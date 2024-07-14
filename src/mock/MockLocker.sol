// SPDX-License-Identifier: MIT
// UBD Network. Full UBDN balance checker
pragma solidity 0.8.26;


contract MockLocker {
    
    uint256 immutable public TOTAL_LOCKED_VALUE;
    uint256 immutable public AVAILABLE_LOCKED_VALUE;

    constructor (uint256 _total, uint256 _available) {
        TOTAL_LOCKED_VALUE = _total;
        AVAILABLE_LOCKED_VALUE = _available;
    }

    function getUserAvailableAmount(address _user)
        external
        view
    returns(uint256 total, uint256 availableNow) {
        return (TOTAL_LOCKED_VALUE, AVAILABLE_LOCKED_VALUE);
    }
}
