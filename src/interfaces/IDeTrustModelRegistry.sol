// SPDX-License-Identifier: MIT
// UBD Network

pragma solidity 0.8.26;

/**
 * @dev Interface of the DeTrustMultisigModelRegistry.
 */
interface IDeTrustModelRegistry {


    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns one byte array:
     *  7    6    5    4    3    2   1   0  <= Bit number(dec)
     *  ------------------------------------------------------
     *  1    1    1    1    1    1   1   1   
     *  |    |    |    |    |    |   |   |   
     *  |    |    |    |    |    |   |   +-Is_Enabled
     *  |    |    |    |    |    |   +-Need_Balance 
     *  |    |    |    |    |    +-Need_FeeCharge
     *  |    |    |    |    +-reserved_core
     *  |    |    |    +-reserved_core
     *  |    |    +-reserved_core
     *  |    +-reserved_core  
     *  +-reserved_core
     */
    function isModelEnable(address _impl, address _creator) 
        external 
        view 
        returns (bytes1 _rules);

    /**
     * @dev Returns `true` or revert with reason.
     */
    function checkRules(address _impl, address _creator)
        external
        view
        returns (bool _ok);

    /**
     * @dev Returns `true` if Fee charged
     */
    function chargeFee(address _impl, address _creator, bytes32 _promoHash)
        external
        payable
        returns (
            address feeToken_, 
            uint256 feeAmount_, 
            address feeBeneficiary_,
            uint64 prePaiedPeriod_);

    function getMinHoldInfo() 
        external 
        view 
        returns (uint256 holdAmount, address holdToken);

   
}
