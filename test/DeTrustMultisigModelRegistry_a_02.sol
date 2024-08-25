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
import {FeeManager_01} from "../src/FeeManager_01.sol";

// 
contract DeTrustMultisigModelRegistry_a_02 is Test {
    address beneficiary = address(100);
    error AddressInsufficientBalance(address account);
    error OwnableUnauthorizedAccount(address account);

    
    DeTrustMultisigModelRegistry public modelReg;
    DeTrustMultisigFactory  public factory;
    UsersDeTrustMultisigRegistry public userReg;
    
    MockERC20 public erc20Hold;

    receive() external payable virtual {}
    function setUp() public {
        
        erc20Hold = new MockERC20('UBDN1 token', 'UBDN1');
        modelReg = new DeTrustMultisigModelRegistry(beneficiary); 
        userReg = new UsersDeTrustMultisigRegistry();
        factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));

        // set hold token contract
        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, 
                address(1))
        );
        modelReg.setMinHoldAddress(address(erc20Hold));
        // by owner
        modelReg.setMinHoldAddress(address(erc20Hold));

    }

    // 
    function test_check_permissions() public {
        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, 
                address(1))
        );
        modelReg.setMinHoldAmount(1);

        uint256 minAmount = modelReg.minHoldAmount();
        vm.expectRevert('Only decrease is possible');
        modelReg.setMinHoldAmount(minAmount + 1);        
        // by owner
        modelReg.setMinHoldAmount(minAmount - 1);

        (uint256 amount, address holdToken) = modelReg.getMinHoldInfo();
        assertEq(amount, minAmount - 1);
        assertEq(holdToken, address(erc20Hold));

        (uint256 amount1, address holdToken1) = factory.getMinHoldInfo();
        assertEq(amount1, minAmount - 1);
        assertEq(holdToken1, address(erc20Hold));
    }
}