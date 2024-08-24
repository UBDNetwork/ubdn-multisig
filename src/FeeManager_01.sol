// SPDX-License-Identifier: MIT
// UBD Network Fee Manager
pragma solidity 0.8.26;

import {ContextUpgradeable, Initializable} from "@Uopenzeppelin/contracts/utils/ContextUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDeTrustFactory.sol";

/**
 * @dev This is abstract contract for manage fee in inheritors
 * 
 * !!! This is implementation contract for proxy contract creation
 */
abstract contract FeeManager_01 is  Initializable,  ContextUpgradeable
{
    
    struct Fee {
        uint256 feeAmount;
        address feeToken;
        uint64  payedTill;
        address feeBeneficiary;
    }

    /// @custom:storage-location erc7201:ubdn.storage.DeTrustMultisigModel_01
    struct FeeManager_01_Storage {
        Fee fee;
        uint64  freeHoldPeriod;
        address factory;
    }

    uint64 public constant ANNUAL_FEE_PERIOD = 365 days;

    // keccak256(abi.encode(uint256(keccak256("ubdn.storage.FeeManager_01_Storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant FeeManager_01_StorageLocation =  0xd9c0a4844f162bd8c6e1703f4c7b7bb107741f9c9261bc1c32b5e10280fc4e00;    
    
    function _getFeeManager_01_StorageStorage() 
        private pure returns (FeeManager_01_Storage storage $) 
    {
        assembly {
            $.slot := FeeManager_01_StorageLocation
        }
    }
    /////////////////////////////////////////////////////
    /// OpenZepelin Pattern for Proxy initialize      ///
    /////////////////////////////////////////////////////

    /*
    // This is initializer code example. Must be implemented once in inheritor
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

    */

    function __FeeManager_01_init(
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
    ) internal onlyInitializing 
    {
        //__Ownable_init_unchained(_owner);
        __FeeManager_01_init_unchained(
             _feeToken, _feeAmount, _feeBeneficiary, _feePrepaidPeriod
        );
    }

    function __FeeManager_01_init_unchained(
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
        
    ) internal onlyInitializing 
    {
        FeeManager_01_Storage storage $ = _getFeeManager_01_StorageStorage();
        $.fee.feeToken = _feeToken;
        $.fee.feeAmount = _feeAmount;
        $.fee.feeBeneficiary = _feeBeneficiary;
        $.fee.payedTill = uint64(block.timestamp) + ANNUAL_FEE_PERIOD + _feePrepaidPeriod;
        $.factory = msg.sender;
        $.freeHoldPeriod = _feePrepaidPeriod;
    }
    ///////////////////////////////////////////////////////////////////////////////////

    


    /**  EXAMPLE METHOD FOR IMPLEMENT IN INHERITOR
     * @dev Use this method for pay in advance any periods. Available only 
     * for trust owner or inheritor
     * @param _numberOfPeriods to pay fee in advance
     */
    // function payFeeAdvance(uint64 _numberOfPeriods) external {
    //     _chargeFee(_numberOfPeriods);
    // }

    /** EXAMPLE METHOD FOR IMPLEMENT IN INHERITOR
     * @dev Use this method for  charge fee debt if exist. Available for 
     * any address, for example platform owner
     */
    // function chargeAnnualFee() external  {
    //     _chargeFee(0);
    // }



    ///////////////////////////////////////////////////////////////////////////
  
   

    /**
     * @dev Returns full FeeManager info
     */
    function geFeeManager_01_StorageInfo() 
        public 
        pure 
    returns(FeeManager_01_Storage memory feeManager){
        feeManager = _getFeeManager_01_StorageStorage();
    }

    /**
     * @dev Returns true during payed period
     */
    function isAnnualFeePayed() public view returns(bool isPayed){
        FeeManager_01_Storage memory $ = _getFeeManager_01_StorageStorage();
        isPayed = $.fee.payedTill >= uint64(block.timestamp); 
    }

    function checkMinHoldRules(address[] calldata _holders) 
        public 
        view 
        returns(bool)
    {
        uint256 currentHoldBalance;
        (uint256 amt, address adr) = _getMinHoldInfo();
        for (uint256 i = 0; i < _holders.length; ++i) {
            currentHoldBalance += IERC20(adr).balanceOf(_holders[i]);
        }
        if (currentHoldBalance >= amt) {
            return true;
        } else {
            return false;
        }

    }


    ////////////////////////////////////////////////////////////////////////

    function _chargeFee(
        uint64 _numberOfPeriods
    ) 
        internal 
        virtual
    {
        FeeManager_01_Storage storage $ = _getFeeManager_01_StorageStorage();
        if (_numberOfPeriods == 0) {
            _numberOfPeriods = _feeDebtPeriodsNumber(
                $.fee.payedTill - ANNUAL_FEE_PERIOD, // LAST PAYED DATE
                uint64(block.timestamp)               // Now
            );
        }
        if ($.fee.feeAmount > 0 && _numberOfPeriods > 0){
            if ($.fee.feeToken != address(0)){
                SafeERC20.safeTransfer(
                    IERC20($.fee.feeToken),
                    $.fee.feeBeneficiary, 
                    $.fee.feeAmount * _numberOfPeriods
                );
            } else {
                address payable s = payable($.fee.feeBeneficiary);
                s.transfer($.fee.feeAmount  * _numberOfPeriods);
            }
            $.fee.payedTill += ANNUAL_FEE_PERIOD * _numberOfPeriods;
        }
    }

    function _feeDebtPeriodsNumber(uint64 _lastPayedDate, uint64 _debtDate) 
        internal 
        pure
        virtual
        returns(uint64 number)
    {
        if (_lastPayedDate  < _debtDate) {
            number = (_debtDate - _lastPayedDate) / ANNUAL_FEE_PERIOD;
        }
    }

    function _getMinHoldInfo() internal view returns (uint256 amt, address adr) {
        FeeManager_01_Storage storage $ = _getFeeManager_01_StorageStorage();
        (amt, adr) = IDeTrustFactory($.factory).getMinHoldInfo();
    }
}
