// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {MockERC20} from "../src/mock/MockERC20.sol";
import {MockLocker} from "../src/mock/MockLocker.sol";

import {BalanceChecker} from "../src/BalanceChecker.sol";


contract BalanceCheker_m_01 is Test {
    uint256 public locked = 2e18;
    uint256 public lockedAvailable = 1e18;
    string public detrustName = 'NameOfDeTrust';
    BalanceChecker public checker;

    MockERC20 public erc20;
    MockLocker public locker;

    receive() external payable virtual {}
    function setUp() public {
        
        locker = new MockLocker(locked, lockedAvailable);
        erc20 = new MockERC20('Mock ERC20 Token', 'MOCK');
        checker = new BalanceChecker(address(erc20), address(locker));
    }

    function test_totalSupply() public {
        assertEq(erc20.balanceOf(address(this)), erc20.totalSupply());
    }
    
    function test_withLockedBalance() public {
        assertEq(checker.balanceOf(address(this)), erc20.totalSupply() + locked);
    }
}
