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

contract DeTrustMultisigOnchainModel_01_a_01 is Test {
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
        console.logBytes1(modelReg.isModelEnable(address(impl_01), address(1)));

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
    }

    // pay fee in deploy time and make operation without fee payment
    function test_proxy() public {
        assertEq(address(factory.modelRegistry()), address(modelReg));
        assertEq(address(factory.trustRegistry()), address(userReg));

        vm.prank(address(11));
        vm.expectRevert(); // there is not enough balance to pay fee
        proxy = payable(factory.deployProxyForTrust(
            address(impl_01), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            promoHash
        ));

        uint256 balanceBefore = erc20.balanceOf(beneficiary);
        // add balance to charge fee
        erc20.transfer(address(11), feeAmount);

        periodOrDateArray[1] = silentPeriod;

        // deploy multisig - success
        vm.startPrank(address(11));
        erc20.approve(address(modelReg), feeAmount);
        uint64 currentTime = uint64(block.timestamp);
        proxy = payable(factory.deployProxyForTrust(
            address(impl_01), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,
            promoHash
        ));
        vm.stopPrank();

        // check fee payment
        assertEq(userReg.getCreatorTrusts(address(1))[0], proxy);
        assertEq(erc20.balanceOf(address(11)), 0);
        assertEq(erc20.balanceOf(beneficiary), balanceBefore + feeAmount);

        // get proxy info
        DeTrustMultisigOnchainModel_01 multisig_instance = DeTrustMultisigOnchainModel_01(proxy);
        DeTrustMultisigOnchainModel_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        
        assertEq(info.ops.length, 0);
        assertEq(info.threshold, threshold);
        assertEq(info.cosigners.length, 5);
        assertEq(info.cosigners[1].validFrom, silentPeriod);
        assertEq(info.cosigners[2].validFrom, 0);
        assertEq(info.cosigners[3].validFrom, 0);
        assertEq(info.cosigners[4].validFrom, 0);
        

        DeTrustMultisigOnchainModel_01.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        assertEq(infoFee.fee.payedTill, currentTime + multisig_instance.ANNUAL_FEE_PERIOD());
        assertEq(infoFee.fee.feeAmount, feeAmount);
        assertEq(infoFee.fee.feeToken, address(erc20));
        assertEq(infoFee.fee.feeBeneficiary, beneficiary);
        assertEq(multisig_instance.isAnnualFeePayed(), true);


        // check UsersDeTrustRegistry
        assertEq(userReg.getInheritorTrusts(address(1))[0], proxy);
        assertEq(userReg.getInheritorTrusts(address(5))[0], proxy);

        // check lastOwnerOp and silentPeriod
        DeTrustMultisigOnchainModel_01.DeTrustMultisigOnchainModel_01_Storage memory infoTrust = 
            multisig_instance.getDeTrustMultisigOnchainModel_01();

        assertEq(infoTrust.lastOwnerOp, currentTime);
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

        // try to create op by owner
        vm.prank(address(1));
        currentTime = uint64(block.timestamp);
        lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);
        infoTrust = multisig_instance.getDeTrustMultisigOnchainModel_01();
        assertEq(infoTrust.lastOwnerOp, currentTime);


        // sign and execute - in silent period. Wait revert!
        vm.prank(address(2));
        vm.expectRevert(
            abi.encodeWithSelector(MultisigOnchainBase_01.CoSignerNotValid.selector, address(2))
        );
        multisig_instance.signAndExecute(lastNonce, true);

        vm.warp(block.timestamp + silentPeriod + 1);
        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNonce, true);
        // wait silent period. Try to sign and execute op

        // check balances
        assertEq(address(15).balance, 1e18);
        assertEq(address(proxy).balance, 0);
        info = multisig_instance.getMultisigOnchainBase_01();
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        // fee is not charged again. Very early!
        assertEq(infoFee.fee.payedTill, payedTillBefore);
        assertEq(info.ops.length, 1);
        assertEq(info.ops[0].signedBy.length, 2);
    }
}