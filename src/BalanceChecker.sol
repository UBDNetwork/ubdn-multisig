// SPDX-License-Identifier: MIT
// UBD Network. Full UBDN balance checker
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Lock {
    uint256 amount;
    uint256 lockedUntil;
}

interface ILocker {

    function getUserLocks(address _user) external returns(Lock[] memory);
    function getUserAvailableAmount(address _user)
        external
        view
        returns(uint256 total, uint256 availableNow);
}
/**
 * @dev This ccontract checks ERC20 token address and
 * available token locks in locker
 */
contract BalanceChecker {
    
    IERC20  public ubdnToken;
    ILocker public ubdnLocker;

    constructor (address _erc20, address _locker){
        require(_erc20 != address(0) && _locker != address(0),
            "No Zero Address"
        );
        ubdnToken = IERC20(_erc20);
        ubdnLocker = ILocker(_locker);
    }

    function balanceOf(address _holder) external view returns(uint256) {
        uint256 tokenHolded = ubdnToken.balanceOf(_holder);
        (uint256 locked, ) = ubdnLocker.getUserAvailableAmount(_holder);
        return tokenHolded + locked;
    }

}
