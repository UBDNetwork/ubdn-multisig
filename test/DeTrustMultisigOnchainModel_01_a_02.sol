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
import {MultisigOnchainBase_01} from "../src/MultisigOnchainBase_01.sol";

contract DeTrustMultisigOnchainModel_01_a_02 is Test {
    uint256 public sendEtherAmount = 1e18;
    uint256 public sendERC20Amount = 2e18;
    uint256 public feeAmount = 5e18;
    uint64 public silentPeriod = 10000;
    string public detrustName = 'NameOfDeTrust';
    string public badDetrustName = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
    address beneficiary = address(100);
    uint8 threshold = 2;
    address owner = address(1);
    error AddressInsufficientBalance(address account);

    DeTrustMultisigFactory  public factory;
    DeTrustMultisigOnchainModel_01 public impl_01;
    UsersDeTrustMultisigRegistry public userReg;
    DeTrustMultisigModelRegistry public modelReg;
    address[] inheritors = new address[](5);
    uint64[] periodOrDateArray = new uint64[](5);
    bytes32  promoHash = 0x0;
    address payable proxy;
    uint64 currentTime;
    uint64 deployTime;

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

        // with fee to create trust
        vm.prank(address(this));
        modelReg.setModelState(
            address(impl_01),
            DeTrustMultisigModelRegistry.TrustModel(0x05, address(0), 0, address(erc20), feeAmount)
        );
        // console.logBytes1(modelReg.isModelEnable(address(impl_01), address(1)));

        userReg.setFactoryState(address(factory), true);
        assertEq(
            uint8(modelReg.isModelEnable(address(impl_01), address(1))), 
            uint8(0x05)
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

        uint256 balanceBefore = erc20.balanceOf(beneficiary);
        // add balance to charge fee
        erc20.transfer(address(11), feeAmount);

        periodOrDateArray[1] = silentPeriod;

        // deploy multisig - success
        vm.startPrank(address(11));
        erc20.approve(address(modelReg), feeAmount);
        proxy = payable(factory.deployProxyForTrust(
            address(impl_01), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,
            promoHash
        ));
        vm.stopPrank();
        deployTime = uint64(block.timestamp);
        balanceBefore;
    }

    // check update lastOwnerDate and using silentTime
    function test_proxy() public {
      
        // get proxy info
        DeTrustMultisigOnchainModel_01 multisig_instance = DeTrustMultisigOnchainModel_01(proxy);
        DeTrustMultisigOnchainModel_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        DeTrustMultisigOnchainModel_01.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        // check lastOwnerOp and silentPeriod
        DeTrustMultisigOnchainModel_01.DeTrustMultisigOnchainModel_01_Storage memory infoTrust = 
            multisig_instance.getDeTrustMultisigOnchainModel_01();

        assertEq(infoTrust.lastOwnerOp, deployTime);
        assertEq(infoTrust.silenceTime, silentPeriod);
        
        // topup trust
        erc20.transfer(proxy, sendERC20Amount);
        address payable _receiver = payable(proxy);
        _receiver.transfer(sendEtherAmount);

        // move time
        vm.warp(block.timestamp + 100);
        // withdraw ether - signer is not owner, now is silent period. Wait revert!
        uint64 payedTillBefore = infoFee.fee.payedTill;
        bytes memory _data = "";
        vm.prank(address(2));
        // create and sign operation
        vm.expectRevert(
            abi.encodeWithSelector(MultisigOnchainBase_01.CoSignerNotValid.selector, address(2))
        );
        uint256 lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);

        // move time - silentPeriod has finished!! Cosigner signs
        vm.warp(block.timestamp + silentPeriod);
        vm.prank(address(2));
        currentTime = uint64(block.timestamp);
        lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);
        infoTrust = multisig_instance.getDeTrustMultisigOnchainModel_01();
        assertEq(infoTrust.lastOwnerOp, deployTime);

        // Cosigner signs
        vm.prank(address(3));
        multisig_instance.signAndExecute(lastNonce, true);

        // check balances
        assertEq(address(15).balance, 1e18);
        assertEq(address(proxy).balance, 0);
        assertEq(infoTrust.lastOwnerOp, deployTime);
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        infoTrust = multisig_instance.getDeTrustMultisigOnchainModel_01();

        // fee is not charged again. Very early!
        assertEq(infoFee.fee.payedTill, payedTillBefore);
        assertEq(info.ops.length, 1);
        assertEq(info.ops[0].signedBy.length, 2);

        // call iAmAlive by cosigner
        vm.prank(address(2));
        vm.expectRevert('Only for creator');
        multisig_instance.iAmAlive();

        // call iAmAlive by owner - lastOwnerOp has been changed
        vm.prank(address(1));
        multisig_instance.iAmAlive();
        infoTrust = multisig_instance.getDeTrustMultisigOnchainModel_01();
        currentTime = uint64(block.timestamp);
        assertEq(infoTrust.lastOwnerOp, currentTime);

        // try to create op by cosigner - now is silent period again - revert!
        vm.prank(address(2));
        vm.expectRevert(
            abi.encodeWithSelector(MultisigOnchainBase_01.CoSignerNotValid.selector, address(2))
        );
        lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);
    }
}