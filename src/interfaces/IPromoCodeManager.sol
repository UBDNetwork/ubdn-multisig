// SPDX-License-Identifier: MIT
// UBD Network

pragma solidity 0.8.26;

/**
 * @dev Interface of the IPromoCodeManager. 
 */
interface IPromoCodeManager {

    
    function getPrepaidPeriod(address _impl, address _creator, bytes32 _promoHash) 
        external
    returns(uint64 prePaidPeriod_);

}
