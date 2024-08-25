// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "forge-std/console.sol";

import {DeTrustMultisigFactory} from "../src/DeTrustMultisigFactory.sol";
import {DeTrustMultisigOnchainModel_Free} from "../src/DeTrustMultisigOnchainModel_Free.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

import {DeTrustMultisigModelRegistry} from "../src/DeTrustMultisigModelRegistry.sol";
import {UsersDeTrustMultisigRegistry} from "../src/UsersDeTrustMultisigRegistry.sol";
import {FeeManager_01} from "../src/FeeManager_01.sol";

// check hold balance + fee in depoly time + required balance
contract DeTrustMultisigOnchainModel_Free_a_03 is Test {
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
    DeTrustMultisigOnchainModel_Free public impl_00;
    UsersDeTrustMultisigRegistry public userReg;
    DeTrustMultisigModelRegistry public modelReg;
    address[] inheritors = new address[](5);
    uint64[] periodOrDateArray = new uint64[](5);
    bytes32  promoHash = 0x0;
    address payable proxy;
    address payable proxy1;

    MockERC20 public erc20;
    MockERC20 public erc20Hold;

    receive() external payable virtual {}
    function setUp() public {
        impl_00 = new DeTrustMultisigOnchainModel_Free();
        erc20 = new MockERC20('UBDN token', 'UBDN');
        erc20Hold = new MockERC20('UBDN1 token', 'UBDN1');
        modelReg = new DeTrustMultisigModelRegistry(beneficiary); 
        userReg = new UsersDeTrustMultisigRegistry();
        factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));

        // with fee in eth to create trust + need balance
        vm.prank(address(this));
        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(0x07, address(erc20), requiredAmount , address(0), feeAmount)
        );
        // set hold token contract
        modelReg.setMinHoldAddress(address(erc20Hold));

        assertEq(modelReg.getModelsList().length, 1);
        assertEq(modelReg.getModelsList()[0], address(impl_00));

        userReg.setFactoryState(address(factory), true);
        assertEq(
            uint8(modelReg.isModelEnable(address(impl_00), address(1))), 
            uint8(0x07)
        );

        // set hold token contract
        modelReg.setMinHoldAddress(address(erc20Hold));

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
        assertEq(address(proxy).balance, 0); // there is not eth on proxy
        assertEq(address(beneficiary).balance, feeAmount);
    }

    // hold balance is not being checked, fee is not being charged
    function test_proxy1() public {
        
        DeTrustMultisigOnchainModel_Free multisig_instance = DeTrustMultisigOnchainModel_Free(proxy);
        // topup proxy
        erc20.transfer(address(proxy), sendERC20Amount);
        bytes memory _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount
        );

        // move time
        vm.warp(block.timestamp + 10000);
        
        uint256 balanceBeforeEth = address(beneficiary).balance;
        uint256 balanceBeforeERC20 = erc20.balanceOf(address(11));

        vm.prank(address(1));
        uint256 lastNone = multisig_instance.createAndSign(address(erc20), 0, _data);
        // get proxy info
        DeTrustMultisigOnchainModel_Free.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.ops[0].signedBy.length, 1);

        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNone, true);
        assertEq(address(beneficiary).balance, balanceBeforeEth);
        assertEq(erc20.balanceOf(address(11)), balanceBeforeERC20 + sendERC20Amount);
    }
}