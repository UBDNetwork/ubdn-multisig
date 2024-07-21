// SPDX-Licence-Identifier: MIT
// MOck
pragma solidity 0.8.26;

import "../FeeManager_01.sol";

contract MockSimpleFee_01 is FeeManager_01 {

    /////////////////////////////////////////////////////
    /// OpenZepelin Pattern for Proxy initialize      ///
    /////////////////////////////////////////////////////
    function initialize(
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
       
    ) public initializer
    {
        __FeeManager_01_init(
            _feeToken, _feeAmount, _feeBeneficiary, _feePrepaidPeriod
        );
    }

    /**  EXAMPLE METHOD FOR IMPLEMENT IN INHERITOR
     * @dev Use this method for pay in advance any periods. Available only 
     * for trust owner or inheritor
     * @param _numberOfPeriods to pay fee in advance
     */
    function payFeeAdvance(uint64 _numberOfPeriods) external {
        _chargeFee(_numberOfPeriods);
    }

    /** EXAMPLE METHOD FOR IMPLEMENT IN INHERITOR
     * @dev Use this method for  charge fee debt if exist. Available for 
     * any address, for example platform owner
     */
    function chargeAnnualFee() external  {
        _chargeFee(0);
    }
 


}