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

contract DeTrustMultisigFactory_a_01 is Test {
    uint256 public sendEtherAmount = 4e18;
    uint256 public sendERC20Amount = 2e18;
    
    uint256 public feeAmount = 5e18;
    uint256 public requiredBalanceForDeploy = 3e18;
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

    }

    // one token to hold and pay fee in deploy time
    function test_promo_1() public {
       
        erc20.transfer(address(1), feeAmount);
        vm.startPrank(address(1));
        erc20.approve(address(modelReg), feeAmount);
        // deploy proxy
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            0x0
        ));
        vm.stopPrank();
        console2.log(erc20.balanceOf(address(1)));
    }
}