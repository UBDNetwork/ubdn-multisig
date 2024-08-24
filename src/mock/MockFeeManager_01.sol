// SPDX-Licence-Identifier: MIT
// MOck
pragma solidity 0.8.26;

import "../FeeManager_01.sol";

contract MockFeeManager_01 is FeeManager_01 {

    
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

    function chargeFee(uint64 _numberOfPeriods)   public {
        _chargeFee(_numberOfPeriods);
    }

    function feeDebtPeriodsNumber(uint64 _lastPayedDate, uint64 _debtDate) 
        external 
        pure 
        returns(uint64 number) 
    {
        number = _feeDebtPeriodsNumber(_lastPayedDate, _debtDate);
    }
}