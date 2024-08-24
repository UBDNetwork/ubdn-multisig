// SPDX-License-Identifier: MIT
// UBD Network

pragma solidity 0.8.26;

/**
 * @dev Interface of the DeTrustMultisigFactoryy.
 */
interface IDeTrustFactory {



    function getMinHoldInfo() 
        external 
        view 
        returns (uint256 minHoldAmount, address holdToken);
   
}
