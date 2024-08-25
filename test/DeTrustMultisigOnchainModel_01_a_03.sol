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

contract DeTrustMultisigOnchainModel_01_a_03 is Test {
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

    MockERC20 public erc20;
    MockERC20 public erc20Hold;

    receive() external payable virtual {}
    function setUp() public {
        impl_01 = new DeTrustMultisigOnchainModel_01();
        erc20 = new MockERC20('UBDN token', 'UBDN');
        erc20Hold = new MockERC20('UBDN1 token', 'UBDN1');
        modelReg = new DeTrustMultisigModelRegistry(beneficiary); 
        userReg = new UsersDeTrustMultisigRegistry();
        factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));

        // with fee in eth to create trust + need balance
        vm.prank(address(this));
        modelReg.setModelState(
            address(impl_01),
            DeTrustMultisigModelRegistry.TrustModel(0x07, address(erc20), requiredAmount , address(erc20), feeAmount)
        );
        // console.logBytes1(modelReg.isModelEnable(address(impl_01), address(1)));

        userReg.setFactoryState(address(factory), true);
        assertEq(
            uint8(modelReg.isModelEnable(address(impl_01), address(1))), 
            uint8(0x07)
        );

        // set hold token contract
        modelReg.setMinHoldAddress(address(erc20Hold));
        // add hold token balance for creator - cosigner[0]
        erc20Hold.transfer(address(1), modelReg.minHoldAmount());
        
        // prepare data to deploy proxy
        for (uint160 i = 1; i < 6; i++) {
            inheritors[i - 1] =  address(i);
            periodOrDateArray[i - 1] = 0;
        }


        // add balance for msg.sender
        erc20.transfer(address(11), feeAmount);
        vm.startPrank(address(11));
        erc20.approve(address(modelReg), feeAmount);
        uint256 balanceBefore = erc20.balanceOf(beneficiary); // fee beneficiary balance
        vm.expectRevert('Too low Balance');
        proxy = payable(factory.deployProxyForTrust(
            address(impl_01), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            promoHash
        ));
        vm.stopPrank();
        // add balance again to msg.sender
        erc20.transfer(address(11), requiredAmount);
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

        assertEq(erc20.balanceOf(address(11)), requiredAmount);
        assertEq(erc20.balanceOf(beneficiary), balanceBefore + feeAmount);

    }

    // charge fee - signAndExecute
    function test_proxy1() public {

        // get proxy info
        DeTrustMultisigOnchainModel_01 multisig_instance = DeTrustMultisigOnchainModel_01(proxy);
        DeTrustMultisigOnchainModel_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        DeTrustMultisigOnchainModel_01.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        // topup proxy
        erc20.transfer(address(proxy), 3 * feeAmount);
        address payable _receiver = payable(proxy);
        _receiver.transfer(sendEtherAmount);

        // move time
        vm.warp(block.timestamp + 3 * multisig_instance.ANNUAL_FEE_PERIOD());
        // withdraw ether
        uint64 payedTillBefore = infoFee.fee.payedTill;
        bytes memory _data = "";
        vm.prank(address(1));
        // create and sign operation
        uint256 lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);

        // sign and execute
        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNonce, true);
        // check balances
        assertEq(address(15).balance, 1e18);
        assertEq(address(proxy).balance, 0);
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        assertEq(infoFee.fee.payedTill, payedTillBefore + 3 * multisig_instance.ANNUAL_FEE_PERIOD());
        assertEq(info.ops.length, 1);
        assertEq(info.ops[0].signedBy.length, 2);
    }

    // charge fee - executeOp
    function test_proxy2() public {

        // get proxy info
        DeTrustMultisigOnchainModel_01 multisig_instance = DeTrustMultisigOnchainModel_01(proxy);
        DeTrustMultisigOnchainModel_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        DeTrustMultisigOnchainModel_01.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        // topup proxy
        erc20.transfer(address(proxy), 3 * feeAmount);
        address payable _receiver = payable(proxy);
        _receiver.transfer(sendEtherAmount);

        // withdraw ether
        uint64 payedTillBefore = infoFee.fee.payedTill;
        bytes memory _data = "";
        vm.prank(address(1));
        // create and sign operation
        uint256 lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);

        // sign and execute
        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNonce, false);
        
        // move time
        vm.warp(block.timestamp + 3 * multisig_instance.ANNUAL_FEE_PERIOD());
        vm.prank(address(3));
        multisig_instance.executeOp(lastNonce);

        // check balances
        assertEq(address(15).balance, 1e18);
        assertEq(address(proxy).balance, 0);
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        assertEq(infoFee.fee.payedTill, payedTillBefore + 3 * multisig_instance.ANNUAL_FEE_PERIOD());
        assertEq(info.ops.length, 1);
        assertEq(info.ops[0].signedBy.length, 2);
    }

    // charge fee - payFeeAdvance
    function test_proxy3() public {

        // get proxy info
        DeTrustMultisigOnchainModel_01 multisig_instance = DeTrustMultisigOnchainModel_01(proxy);
        DeTrustMultisigOnchainModel_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        DeTrustMultisigOnchainModel_01.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        // topup proxy
        erc20.transfer(address(proxy), 2 * feeAmount);
        
        // withdraw ether
        uint64 payedTillBefore = infoFee.fee.payedTill;
        bytes memory _data = abi.encodeWithSignature(
            "payFeeAdvance(uint64)",
            2
        );
        vm.prank(address(1));
        uint256 lastNonce = multisig_instance.createAndSign(address(proxy), 0, _data);
        uint256 balanceBefore = erc20.balanceOf(beneficiary);

        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNonce, true);

        // check balances
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        assertEq(infoFee.fee.payedTill, payedTillBefore + 2 * multisig_instance.ANNUAL_FEE_PERIOD());
        assertEq(info.ops.length, 1);
        assertEq(erc20.balanceOf(beneficiary), balanceBefore + 2 * feeAmount);
    }

    // charge fee - chargeAnnualFee
    function test_proxy4() public {

        // get proxy info
        DeTrustMultisigOnchainModel_01 multisig_instance = DeTrustMultisigOnchainModel_01(proxy);
        DeTrustMultisigOnchainModel_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        DeTrustMultisigOnchainModel_01.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        // topup proxy
        erc20.transfer(address(proxy), feeAmount);
        
        // withdraw ether
        uint64 payedTillBefore = infoFee.fee.payedTill;
        uint256 balanceBefore = erc20.balanceOf(beneficiary);
        vm.prank(address(1));
        vm.warp(multisig_instance.ANNUAL_FEE_PERIOD() + 1);

        multisig_instance.chargeAnnualFee();
        // check balances
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        assertEq(infoFee.fee.payedTill, payedTillBefore + multisig_instance.ANNUAL_FEE_PERIOD());
        assertEq(info.ops.length, 0);
        assertEq(erc20.balanceOf(beneficiary), balanceBefore + feeAmount);

        // try again
        payedTillBefore = infoFee.fee.payedTill;
        balanceBefore = erc20.balanceOf(beneficiary);
        vm.prank(address(1));
        multisig_instance.chargeAnnualFee();
        // check balances
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        assertEq(infoFee.fee.payedTill, payedTillBefore);
        assertEq(erc20.balanceOf(beneficiary), balanceBefore);
    }

    // charge fee - executeOp batch
    function test_proxy5() public {

        // get proxy info
        DeTrustMultisigOnchainModel_01 multisig_instance = DeTrustMultisigOnchainModel_01(proxy);
        DeTrustMultisigOnchainModel_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        DeTrustMultisigOnchainModel_01.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        // topup proxy
        erc20.transfer(address(proxy), feeAmount);
        erc20.transfer(address(proxy), sendERC20Amount);
        
        // withdraw ether
        uint64 payedTillBefore = infoFee.fee.payedTill;
        uint256 balanceBefore = erc20.balanceOf(beneficiary);
        uint256 balanceBefore11 = erc20.balanceOf(address(11));
        //console2.log(erc20.balanceOf(address(11)));
        bytes memory _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount/2
        );
        uint256[] memory nonces = new uint256[](2);
        uint256 lastNonce;

        for (uint256 i = 0; i < 2; ++ i) {
            // signer creates and sign the operation
            vm.startPrank(address(1));
            lastNonce = multisig_instance.createAndSign(address(erc20), 0, _data);
            nonces[i] = lastNonce;
            vm.stopPrank();

            // sign and execute
            vm.prank(address(2));
            multisig_instance.signAndExecute(lastNonce, false);
        }
        vm.warp(multisig_instance.ANNUAL_FEE_PERIOD() + 1);

        multisig_instance.executeOp(nonces);
        // check balances
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        assertEq(infoFee.fee.payedTill, payedTillBefore + multisig_instance.ANNUAL_FEE_PERIOD());
        assertEq(info.ops.length, 2);
        assertEq(erc20.balanceOf(beneficiary), balanceBefore + feeAmount);
        assertEq(erc20.balanceOf(address(11)), balanceBefore11 + sendERC20Amount);
    }
}