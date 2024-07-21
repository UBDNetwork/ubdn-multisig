// SPDX-License-Identifier: MIT
// UBD Network DeTrustModel_01_Executive
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {Address} from "@openzeppelin/contracts/utils/Address.sol";
// import {ContextUpgradeable, Initializable} from "@Uopenzeppelin/contracts/utils/ContextUpgradeable.sol";
// import "@Uopenzeppelin/contracts/utils/cryptography/EIP712Upgradeable.sol"; 
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 
import "./MultisigOffchainBase_01.sol";

/**
 * @dev This is a  trust model implementation that can execute any encoded transactions.
 * Upon creation the address of the heir(s) and 
 * the time (dT) of the owner’s absence(silence) are passed. When the heir 
 * applies, this time of inactivity of the owner will be checked. If it is 
 * greater than dT, then both the creator and the heir have access 
 * to the wallet's assets. 
 * 
 * !!! This is implementation contract for proxy conatract creation
 */
contract DeTrustMultisigModel_01 is MultisigOffchainBase_01
    // Initializable, 
    // ContextUpgradeable,
    // EIP712Upgradeable
{
    //using ECDSA for bytes32;
    
    struct Fee {
        uint256 feeAmount;
        address feeToken;
        uint64  payedTill;
        address feeBeneficiary;
    }

    // struct TxSingCheck {
    //     address signer;
    //     bool isValid;
    //     bool signOK;
    // }
    /// @custom:storage-location erc7201:ubdn.storage.DeTrustMultisigModel_01
    struct DeTrustModelStorage_01 {
        uint256 lastOwnerOp;
        bool inherited;
        Fee fee;
    }

    uint64 public constant ANNUAL_FEE_PERIOD = 365 days;

    // keccak256(abi.encode(uint256(keccak256("ubdn.storage.DeTrustMultisigModel_01")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant DeTrustModelStorage_01Location =  0xcf4a3a360b04d36570cb6bdd7ba148570ed50f35bf2cf98d796cd5493321bd00;    
    
    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);
    event EtherTransfer(address sender, uint256 amount);

    /**
     * @dev Throws if called by any account other than the creator 
     *  or inheritor after silence time.
     */
    modifier onlyCreatorOrInheritor() {
        _checkCreatorOrInheritor();
        _;
    }

   

    // /**
    //  * @dev Throws if called by any account other than the creator 
    //  *  or inheritor after silence time.
    //  */
    // modifier whenSigned() {
    //     _checkSignatures();
    //     _;
    // }

    constructor() {
      _disableInitializers();
    }

    function initialize(
        uint8 _threshold,
        address[] calldata _inheritors,
        uint64[] calldata _silence,
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
       
    ) public initializer
    {
        __DeTrustMultisigModel_01_init(
            _feeToken, _feeAmount, _feeBeneficiary, _feePrepaidPeriod
        );
        
        // In this model we use 1st cosigners slot as owner(or creator) slot
        require(_silence[0] == 0, "Cant restrict owners sign");
        __MultisigOffchainBase_01_init(
            _threshold, _inheritors, _silence
        );
        
        __EIP712_init("UBDN DeTrust Multisig", "0.0.1");

    }

    /**
     * @dev Sets the sender as the initial owner, the beneficiary as the pending owner, 
     * the start timestamp and the
     * vesting duration of the vesting wallet.
     */
    function __DeTrustMultisigModel_01_init(
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
    ) internal onlyInitializing 
    {
        //__Ownable_init_unchained(_owner);
        __DeTrustMultisigModel_01_init_unchained(
             _feeToken, _feeAmount, _feeBeneficiary, _feePrepaidPeriod
        );
    }

    function __DeTrustMultisigModel_01_init_unchained(
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
        
    ) internal onlyInitializing 
    {
        
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        $.lastOwnerOp = block.timestamp;
        $.fee.feeToken = _feeToken;
        $.fee.feeAmount = _feeAmount;
        $.fee.feeBeneficiary = _feeBeneficiary;
        $.fee.payedTill = uint64(block.timestamp) + ANNUAL_FEE_PERIOD + _feePrepaidPeriod;
        
    }


    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {
        emit EtherTransfer(msg.sender, msg.value);
    }

    
    /**
     * @dev Call this method for extend (reset) silnce time counter.
     */
    function iAmAlive() external onlyCreatorOrInheritor {
       DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
       _chargeFee($, 0);
       _updateLastOwnerOp($);
    }

    /**
     * @dev Use this method for interact any dApps onchain
     * @param _target address of dApp smart contract
     * @param _value amount of native token in tx(msg.value)
     * @param _data ABI encoded transaction payload
     */
    function executeOp(
        address _target,
        uint256 _value,
        bytes memory _data,
        bytes[] memory _signatures
    ) public onlyCreatorOrInheritor returns (bytes memory r) {
        //require(_target != address(this), "No Trust itself");
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        _chargeFee($, 0);
        r = _checkSignaturesAndExecute(_target, _value, _data, _signatures);
        _updateLastOwnerOp($);
    }

    /**
     * @dev Use this method for interact any dApps onchain, executing as one batch
     * @param _targetArray addressed of dApp smart contract
     * @param _valueArray amount of native token in every tx(msg.value)
     * @param _dataArray ABI encoded transaction payloads
     * 
     * @param _signaturesArray array if signatures array for each tx
     * https://docs.soliditylang.org/en/develop/types.html#arrays
     * For example, if you have a variable uint[][5] memory x, you access the seventh 
     * uint in the third dynamic array using x[2][6], and to access the third dynamic 
     * array, use x[2]. Again, if you have an array T[5] a for a type T that can also 
     * be an array, then a[2] always has type T.
     */
    function executeMultiOp(
        address[] calldata _targetArray,
        uint256[] calldata _valueArray,
        bytes[] memory _dataArray,
        bytes[][] memory _signaturesArray
    ) external  returns (bytes[] memory r) {
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        _chargeFee($, 0);
        _updateLastOwnerOp($);
        r = new bytes[](_dataArray.length);
        for (uint256 i = 0; i < _dataArray.length; ++ i){
            r[i] =executeOp(_targetArray[i], _valueArray[i], _dataArray[i], _signaturesArray[i]);
        }
        _updateLastOwnerOp($);
    }


    /**
     * @dev Use this method for pay in advance any periods. Available only 
     * for trust owner or inheritor
     * @param _numberOfPeriods to pay fee in advance
     */
    function payFeeAdvance(uint64 _numberOfPeriods) external onlyCreatorOrInheritor {
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        _chargeFee($, _numberOfPeriods);
    }

    /**
     * @dev Use this method for  charge fee debt if exist. Available for 
     * any address, for example platform owner
     */
    function chargeAnnualFee() external  {
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        _chargeFee($, 0);
    }



    ///////////////////////////////////////////////////////////////////////////
  
    /**
     * @dev Returns creator of DeTrust proxy
     */
    function creator() external pure returns(address){
        //DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        return getMultisigOffchainBase_01().cosigners[0].signer ;
    }

    /**
     * @dev Returns full DeTrust info
     */
    function getDeTrustMultisigInfo_01() external pure returns(DeTrustModelStorage_01 memory trust){
        trust = _getDeTrustModel_01_ExecutiveStorage();
    }

    /**
     * @dev Returns true during payed period
     */
    function isAnnualFeePayed() external view returns(bool isPayed){
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        isPayed = $.fee.payedTill >= uint64(block.timestamp); 
    }


    ////////////////////////////////////////////////////////////////////////

    function _chargeFee(
        DeTrustModelStorage_01 storage st, 
        uint64 _numberOfPeriods
    ) internal 
    {
        if (_numberOfPeriods == 0) {
            _numberOfPeriods = _feeDebtPeriodsNumber(
                st.fee.payedTill - ANNUAL_FEE_PERIOD, // LAST PAYED DATE
                uint64(block.timestamp)               // Now
            );
        }
        if (st.fee.feeAmount > 0 && _numberOfPeriods > 0){
            if (st.fee.feeToken != address(0)){
                SafeERC20.safeTransfer(
                    IERC20(st.fee.feeToken),
                    st.fee.feeBeneficiary, 
                    st.fee.feeAmount * _numberOfPeriods
                );
            } else {
                address payable s = payable(st.fee.feeBeneficiary);
                s.transfer(st.fee.feeAmount  * _numberOfPeriods);
            }
            st.fee.payedTill += ANNUAL_FEE_PERIOD * _numberOfPeriods;
        }
    }

    function _feeDebtPeriodsNumber(uint64 _lastPayedDate, uint64 _debtDate) 
        internal 
        pure
        returns(uint64 number)
    {
        if (_lastPayedDate  < _debtDate) {
            number = (_debtDate - _lastPayedDate) / ANNUAL_FEE_PERIOD;
        }
    }

    /**
     * @dev Refresh last operation timestamp
     */
    function  _updateLastOwnerOp(DeTrustModelStorage_01 storage st) internal {
        if (!st.inherited) {
            // update only till inhereted moment
            st.lastOwnerOp = block.timestamp;
        }
    }

    /**
     * @dev Throws if the sender is not the owner
     *  or inheritor after silence time. Can`t be restricted to view
     * because have hooks
     */
    function _checkCreatorOrInheritor() internal  virtual {
        //DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        (bool isInInheritorList, ) = isSignerValid(_msgSender());
         if ( !isInInheritorList){
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    // function _isInList(DeTrustModelStorage_01 storage st) internal view 
    //     returns(bool r, uint256 silenceTime_)
    // {
    //     // start from second[1] element because first[0] is crteator
    //     for (uint256 i = 1; i < st.inheritors.length; ++ i) {
    //         if (st.inheritors[i] == _msgSender()) {
    //             r = true;
    //             silenceTime_ = uint256(st.silenceTime[i]);
    //             break;
    //         }
    //     }
    // }

    function _getDeTrustModel_01_ExecutiveStorage() 
        private pure returns (DeTrustModelStorage_01 storage $) 
    {
        assembly {
            $.slot := DeTrustModelStorage_01Location
        }
    }

    
    /**
     * @dev Overiding of parent`s  function to change logic of
     * signer`s validity check. In this model we use `silenceTime` -
     * if there is no creator`s operations in this period then signers
     * became to valid state
     */
    function _isValidSignerRecord(Signer[] memory _cosigners, uint256 _signerIndex)
        internal
        override
        view
        returns(bool valid)
    {
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        // !!!! Main signer validity rule  is here
        valid = _cosigners[_signerIndex].validFrom + $.lastOwnerOp <= block.timestamp;
    } 

    /**
     * @dev use this hook here for update `inherited` property
     * in case of validity(inclidu time) at least one of non creator's
     * signature
     */
    function _hookValidSiner(
        uint256 _signerIndex,
        uint256 _signerAddress,
        uint256 _signatureIndex, 
        uint8   _thresholdCounter
    ) internal 
    {
        if (_signerIndex != 0){
            DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
            // TODO gas safe with if
            $.inherited = true;
        }
        // To suppress compiler warnings
        _signerAddress;
        _signatureIndex;
        _thresholdCounter;
    }
}
