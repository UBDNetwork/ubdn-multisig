// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "forge-std/console.sol";

import {DeTrustMultisigOnchainModel_00} from "../src/DeTrustMultisigOnchainModel_00.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

import {DeTrustMultisigModelRegistry} from "../src/DeTrustMultisigModelRegistry.sol";

// eth fee
contract DeTrustMultisigModelRegistry_a_01 is Test {
    
    DeTrustMultisigOnchainModel_00 public impl_00;
    DeTrustMultisigOnchainModel_00 public impl_01;
    DeTrustMultisigModelRegistry public modelReg;
    MockERC20 public erc20;
    address beneficiary = address(100);
    uint256 feeAmount = 1e18;
    error OwnableUnauthorizedAccount(address sender);

    receive() external payable virtual {}
    function setUp() public {
        impl_00 = new DeTrustMultisigOnchainModel_00();
        impl_01 = new DeTrustMultisigOnchainModel_00();
        erc20 = new MockERC20('UBDN token', 'UBDN');
        modelReg = new DeTrustMultisigModelRegistry(beneficiary);
    }

    // onlyOwner functions
    function test_modelReg() public {

        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(1))
        );
        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(0x07, address(0), 0 , address(0), feeAmount)
        );

        vm.expectRevert('Please enable check balance');
        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(0x01, address(erc20), 1 , address(0), feeAmount)
        );

        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(0x05, address(0), 0 , address(0), feeAmount)
        );

        modelReg.setModelState(
            address(impl_01),
            DeTrustMultisigModelRegistry.TrustModel(0x05, address(0), 0 , address(0), feeAmount)
        );

        assertEq(modelReg.getModelsList().length, 2);

        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(1))
        );
        modelReg.removeModel(address(impl_00));

        modelReg.removeModel(address(impl_00));

        assertEq(modelReg.getModelsList().length, 1);
        assertEq(modelReg.getModelsList()[0], address(impl_01));

        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(1))
        );
        modelReg.setPromoCodeManager(address(1));

        modelReg.setPromoCodeManager(address(1));

        assertEq(modelReg.promoCodeManager(), address(1));

    }
}