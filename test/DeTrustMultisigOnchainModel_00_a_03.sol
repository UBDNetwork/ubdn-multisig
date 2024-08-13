// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "forge-std/console.sol";

import {DeTrustMultisigFactory} from "../src/DeTrustMultisigFactory.sol";
import {DeTrustMultisigOnchainModel_00} from "../src/DeTrustMultisigOnchainModel_00.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

import {DeTrustMultisigModelRegistry} from "../src/DeTrustMultisigModelRegistry.sol";
import {UsersDeTrustMultisigRegistry} from "../src/UsersDeTrustMultisigRegistry.sol";

// eth fee
contract DeTrustMultisigOnchainModel_00_a_03 is Test {
    uint256 public sendEtherAmount = 1e18;
    uint256 public sendERC20Amount = 2e18;
    uint256 public feeAmount = 5e18;
    uint256 public requiredAmount = 6e18;
    uint64 public silentPeriod = 10000;
    string public detrustName = 'NameOfDeTrust';
    string public badDetrustName = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
    address beneficiary = address(100);
    uint8 threshold = 2;
    error AddressInsufficientBalance(address account);

    DeTrustMultisigFactory  public factory;
    DeTrustMultisigOnchainModel_00 public impl_00;
    UsersDeTrustMultisigRegistry public userReg;
    DeTrustMultisigModelRegistry public modelReg;
    address[] inheritors = new address[](5);
    uint64[] periodOrDateArray = new uint64[](5);
    bytes32  promoHash = 0x0;
    address payable proxy;
    address payable proxy1;

    MockERC20 public erc20;

    receive() external payable virtual {}
    function setUp() public {
        impl_00 = new DeTrustMultisigOnchainModel_00();
        erc20 = new MockERC20('UBDN token', 'UBDN');
        modelReg = new DeTrustMultisigModelRegistry(beneficiary); 
        userReg = new UsersDeTrustMultisigRegistry();
        factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));

        // with fee in eth to create trust + need balance
        vm.prank(address(this));
        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(0x07, address(erc20), requiredAmount , address(0), feeAmount)
        );
        assertEq(modelReg.getModelsList().length, 1);
        assertEq(modelReg.getModelsList()[0], address(impl_00));

        userReg.setFactoryState(address(factory), true);
        assertEq(
            uint8(modelReg.isModelEnable(address(impl_00), address(1))), 
            uint8(0x07)
        );
        // prepare data to deploy proxy
        for (uint160 i = 1; i < 6; i++) {
            inheritors[i - 1] =  address(i);
            periodOrDateArray[i - 1] = 0;
        }

        // add balance for msg.sender
        address payable _receiver = payable(address(11));
        _receiver.transfer(3 * feeAmount);

        erc20.transfer(address(11), requiredAmount);
        vm.startPrank(address(11));
        proxy = payable(factory.deployProxyForTrust{value: 3 * feeAmount}(
            address(impl_00), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            promoHash
        ));
        vm.stopPrank();

        assertEq(beneficiary.balance, feeAmount);
        assertEq(address(11).balance, 2 * feeAmount); // check eth back

        // non-supported model
        vm.expectRevert('Model not approved');
        proxy1 = payable(factory.deployProxyForTrust{value: 3 * feeAmount}(
            address(1), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            promoHash
        ));
    }

    // charge fee - signAndExecute - eth fee
    function test_proxy1() public {
        // get proxy info
        DeTrustMultisigOnchainModel_00 multisig_instance = DeTrustMultisigOnchainModel_00(proxy);
        DeTrustMultisigOnchainModel_00.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        DeTrustMultisigOnchainModel_00.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        // topup proxy
        erc20.transfer(address(proxy), sendERC20Amount);
        address payable _receiver = payable(proxy);
        _receiver.transfer(3 * feeAmount);
        bytes memory _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount
        );

        // move time
        vm.warp(block.timestamp + multisig_instance.ANNUAL_FEE_PERIOD());
        uint64 payedTillBefore = infoFee.fee.payedTill;
        uint256 balanceBeforeEth = address(beneficiary).balance;
        uint256 balanceBeforeERC20 = erc20.balanceOf(address(11));
        vm.prank(address(1));
        // create and sign operation
        uint256 lastNonce = multisig_instance.createAndSign(address(erc20), 0, _data);

        // sign and execute
        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNonce, true);
        // check balances
        assertEq(erc20.balanceOf(address(11)), balanceBeforeERC20 + sendERC20Amount);
        assertEq(address(proxy).balance, 2 * feeAmount);
        assertEq(address(beneficiary).balance, balanceBeforeEth + feeAmount);
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        assertEq(infoFee.fee.payedTill, payedTillBefore + multisig_instance.ANNUAL_FEE_PERIOD());
        assertEq(info.ops.length, 1);
        assertEq(info.ops[0].signedBy.length, 2);
    }
}