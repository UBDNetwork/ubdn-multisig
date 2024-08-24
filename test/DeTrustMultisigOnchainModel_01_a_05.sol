// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "forge-std/console.sol";

import {DeTrustMultisigFactory} from "../src/DeTrustMultisigFactory.sol";
import {DeTrustMultisigOnchainModel_01} from "../src/DeTrustMultisigOnchainModel_01.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

import {DeTrustMultisigModelRegistry} from "../src/DeTrustMultisigModelRegistry.sol";
import {UsersDeTrustMultisigRegistry} from "../src/UsersDeTrustMultisigRegistry.sol";


contract DeTrustMultisigOnchainModel_01_a_05 is Test {
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
    DeTrustMultisigOnchainModel_01 public impl_01;
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
        impl_01 = new DeTrustMultisigOnchainModel_01();
        erc20 = new MockERC20('UBDN token', 'UBDN');
        modelReg = new DeTrustMultisigModelRegistry(beneficiary); 
        userReg = new UsersDeTrustMultisigRegistry();
        factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));

        // with fee in eth to create trust + need balance
        vm.prank(address(this));
        modelReg.setModelState(
            address(impl_01),
            DeTrustMultisigModelRegistry.TrustModel(0x01, address(0), 0 , address(0), 0)
        );
        assertEq(modelReg.getModelsList().length, 1);
        assertEq(modelReg.getModelsList()[0], address(impl_01));

        userReg.setFactoryState(address(factory), true);
        assertEq(
            uint8(modelReg.isModelEnable(address(impl_01), address(1))), 
            uint8(0x01)
        );
        // prepare data to deploy proxy
        for (uint160 i = 1; i < 6; i++) {
            inheritors[i - 1] =  address(i);
            periodOrDateArray[i - 1] = 0;
        }
    }

    // does not charge fee - no fee
    function test_proxy1() public {

        vm.startPrank(address(11));
        proxy = payable(factory.deployProxyForTrust(
            address(impl_01), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            promoHash
        ));
        vm.stopPrank();

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

        // get proxy info
        DeTrustMultisigOnchainModel_01 multisig_instance = DeTrustMultisigOnchainModel_01(proxy);
        DeTrustMultisigOnchainModel_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        DeTrustMultisigOnchainModel_01.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        // topup proxy
        erc20.transfer(address(proxy), sendERC20Amount);
        bytes memory _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount
        );

        // move time
        vm.warp(block.timestamp + multisig_instance.ANNUAL_FEE_PERIOD() + 1000);
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
        
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        assertEq(infoFee.fee.payedTill, payedTillBefore);
        assertEq(info.ops.length, 1);
        assertEq(info.ops[0].signedBy.length, 2);
        balanceBeforeEth;
    }
}