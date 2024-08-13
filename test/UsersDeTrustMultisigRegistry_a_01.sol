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
contract UsersDeTrustMultisigRegistry_a_01 is Test {
    
    DeTrustMultisigFactory  public factory;
    DeTrustMultisigOnchainModel_00 public impl_00;
    UsersDeTrustMultisigRegistry public userReg;
    DeTrustMultisigModelRegistry public modelReg;
    address beneficiary = address(100);
    uint256 feeAmount = 1e18;
    string public detrustName = 'NameOfDeTrust';
    error OwnableUnauthorizedAccount(address sender);

    receive() external payable virtual {}
    function setUp() public {
        impl_00 = new DeTrustMultisigOnchainModel_00();
        modelReg = new DeTrustMultisigModelRegistry(beneficiary); 
        userReg = new UsersDeTrustMultisigRegistry();
        factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));
    }

    // onlyOwner functions
    function test_userReg() public {
        address[] memory inheritors = new address[](2);
        inheritors[0] = address(1);
        inheritors[1] = address(2);

        vm.expectRevert('NonAuthorized factory');
        userReg.registerTrust(address(impl_00), inheritors, detrustName);

        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(1))
        );
        userReg.setFactoryState(
            address(2),
            true
        );
    }
}