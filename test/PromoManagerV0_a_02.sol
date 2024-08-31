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
import {MultisigOnchainBase_01} from "../src/MultisigOnchainBase_01.sol";
import {PromoManagerV0} from "../src/PromoManagerV0.sol";

contract PromoManagerV0_a_02 is Test {
    uint256 public sendEtherAmount = 4e18;
    uint256 public sendERC20Amount = 2e18;

    uint256 validTill = 10000;
    uint64 promoPeriod = 365 days;

    uint256 public feeAmount = 5e18;
    uint256 public requiredBalanceForDeploy = 4e18;
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
    PromoManagerV0 public promoManager;
    address[] inheritors = new address[](5);
    uint64[] periodOrDateArray = new uint64[](5);
    string promoCode = 'detrustPromo';
    bytes32 promoHash;
    address payable proxy;

    MockERC20 public erc20;
    MockERC20 public erc20Hold;

    receive() external payable virtual {}
    function setUp() public {
        impl_00 = new DeTrustMultisigOnchainModel_00();
        erc20 = new MockERC20('UBDN token', 'UBDN');
        erc20Hold = new MockERC20('UBDN1 token', 'UBDN1');
        modelReg = new DeTrustMultisigModelRegistry(beneficiary); 
        userReg = new UsersDeTrustMultisigRegistry();
        factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));
        promoManager = new PromoManagerV0();

        // with fee to create trust
        vm.prank(address(this));
        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(0x07, address(erc20), requiredBalanceForDeploy, address(erc20), feeAmount)
        );
        // console.logBytes1(modelReg.isModelEnable(address(impl_00), address(1)));

        // set hold token contract
        modelReg.setMinHoldAddress(address(erc20Hold));
        // add hold token balance for creator - cosigner[0]
        // erc20Hold.transfer(address(1), modelReg.minHoldAmount());

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
        //setup silent period for address(5)
        periodOrDateArray[4] = 100000;

        // promo settings - common promo
        modelReg.setPromoCodeManager(address(promoManager));
        promoHash = promoManager.hlpGetPromoHash(promoCode);
        PromoManagerV0.PromoPeriod memory promoData = PromoManagerV0.PromoPeriod(validTill, promoPeriod);
        promoManager.setPromoPeriod(promoHash, promoData);
    }

    // there are fee, hold to creation, hold to using
    // common promo is unactive - deploy proxy and make action
    // need all things to deploy and using
    // promoCode is expired
    function test_promo_1() public {
        // now promoCode is expired
        vm.warp(validTill + 1);
        uint64 prepaidPeriod = promoManager.getPrepaidPeriod(address(impl_00), address(1), promoHash);
        assertEq(prepaidPeriod, 0);

        // user has done all conditions to deploy    
        vm.startPrank(address(1));
        // deploy proxy
        vm.expectRevert('Too low Balance');
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            promoHash // expired promo
        ));
        vm.stopPrank();

        erc20.transfer(address(1), feeAmount);
        erc20.transfer(address(1), requiredBalanceForDeploy);
        erc20Hold.transfer(address(1), modelReg.minHoldAmount());

        vm.startPrank(address(1));
        erc20.approve(address(modelReg), feeAmount);
        // deploy proxy
        uint64 currentTime = uint64(block.timestamp);
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            promoHash // expired promo
        ));
        vm.stopPrank();


        // get proxy info
        DeTrustMultisigOnchainModel_00 multisig_instance = DeTrustMultisigOnchainModel_00(proxy);
        
        DeTrustMultisigOnchainModel_00.FeeManager_01_Storage memory infoFee = multisig_instance.geFeeManager_01_StorageInfo();
        assertEq(infoFee.fee.payedTill, currentTime + multisig_instance.ANNUAL_FEE_PERIOD()); // without promo period free
        assertEq(infoFee.freeHoldPeriod, currentTime); // without promo period free
        assertEq(infoFee.fee.feeAmount, feeAmount);
        assertEq(infoFee.fee.feeToken, address(erc20));
        assertEq(infoFee.fee.feeBeneficiary, beneficiary);
        assertEq(multisig_instance.isAnnualFeePayed(), true);

        // topup trust
        erc20.transfer(proxy, sendERC20Amount);
        address payable _receiver = payable(proxy);
        _receiver.transfer(sendEtherAmount);

        // move time
        vm.warp(block.timestamp + 100);
        // withdraw ether
        uint64 payedTillBefore = infoFee.fee.payedTill;
        bytes memory _data = "";
        vm.prank(address(1));
        // create and sign operation
        uint256 lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);

        // sign and execute - cosigner
        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNonce, true);
        // check balances
        assertEq(address(15).balance, 1e18);
        assertEq(address(proxy).balance, sendEtherAmount - 1e18);
        infoFee = multisig_instance.geFeeManager_01_StorageInfo();

        assertEq(infoFee.fee.payedTill, payedTillBefore);

        vm.warp(multisig_instance.ANNUAL_FEE_PERIOD() + 1);
        vm.prank(address(1));
        vm.expectRevert();
        lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);
    }
}