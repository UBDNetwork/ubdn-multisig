// SPDX-Licence-Identifier: MIT
// UBD Network DeTrustMultisigOnchainModel_00
pragma solidity 0.8.26;

import "./MultisigOnchainBase_01.sol";
import "./FeeManager_01.sol";

/**
 * @dev This is a  trust model onchain multisig implementation.
 * Upon creation the addresses of the heirs(co-signers) and 
 * the time (T) from each cosigner can sign transactios. 
 * 
 * !!! This is implementation contract for proxy conatract creation
 */
contract DeTrustMultisigOnchainModel_00 is MultisigOnchainBase_01, FeeManager_01 {

    /////////////////////////////////////////////////////
    /// OpenZepelin Pattern for Proxy initialize      ///
    /////////////////////////////////////////////////////
    function initialize(
        uint8 _threshold,
        address[] calldata _cosignersAddresses,
        uint64[] calldata _validFrom,
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
       
    ) public initializer
    {
        require(_validFrom[0] == 0, "Owner must be always able to sign");
        __MultisigOnchainBase_01_init(
            _threshold, _cosignersAddresses, _validFrom
        );

        __FeeManager_01_init(
            _feeToken, _feeAmount, _feeBeneficiary, _feePrepaidPeriod
        );
    }

     /**  
     * @dev Use this method for pay in advance any periods. Available only 
     * for trust owner or inheritor
     * @param _numberOfPeriods to pay fee in advance
     */
    function payFeeAdvance(uint64 _numberOfPeriods) external {
        _chargeFee(_numberOfPeriods);
    }

    /** 
     * @dev Use this method for  charge fee debt if exist. Available for 
     * any address, for example platform owner
     */
    function chargeAnnualFee() external  {
        _chargeFee(0);
    }

}