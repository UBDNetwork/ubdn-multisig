// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {UBDerc20} from "../src/mock/UBDerc20.sol";


contract Ubd_token_m_01 is Test {
    uint256 public sendERC20Amount = 2e18;
    string public detrustName = 'NameOfDeTrust';

    UBDerc20 public erc20;

    receive() external payable virtual {}
    function setUp() public {
        erc20 = new UBDerc20(address(1));
        
    }

    function test_erc20_props() public view{
        assertEq(erc20.totalSupply(), 1e30);
        assertEq(erc20.decimals(), 18);
        assertEq(erc20.name(), 'United Blockchain Dollar');
        assertEq(erc20.symbol(), 'UBD');
        assertEq(erc20.totalSupply(),erc20.balanceOf(address(1)));
    }

    function test_erc20_transfer() public {
        vm.prank(address(1));
        erc20.transfer(address(2),sendERC20Amount);
        assertEq(erc20.balanceOf(address(2)), sendERC20Amount);
        vm.prank(address(2));
        erc20.approve(address(3),sendERC20Amount);
        vm.prank(address(3));
        erc20.transferFrom(address(2), address(1), sendERC20Amount);
        assertEq(erc20.balanceOf(address(2)), 0);
        assertEq(erc20.balanceOf(address(1)), erc20.totalSupply());

    }

    
}
