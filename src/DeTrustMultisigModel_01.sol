// SPDX-License-Identifier: MIT
// UBD Network DeTrustModel_01_Executive
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ContextUpgradeable, Initializable} from "@Uopenzeppelin/contracts/utils/ContextUpgradeable.sol";
import "@Uopenzeppelin/contracts/utils/cryptography/EIP712Upgradeable.sol"; 
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 

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
contract DeTrustMultisigModel_01 is 
    Initializable, 
    ContextUpgradeable,
    EIP712Upgradeable
{
    using ECDSA for bytes32;
    
    struct Fee {
        uint256 feeAmount;
        address feeToken;
        uint64  payedTill;
        address feeBeneficiary;
    }

    struct TxSingCheck {
        address signer;
        bool isValid;
        bool signOK;
    }
    /// @custom:storage-location erc7201:ubdn.storage.DeTrustMultisigModel_01
    struct DeTrustModelStorage_01 {
        uint256 lastOwnerOp;
        uint256 nonce;
        bool inherited;
        uint8 threshold;
        Fee fee;
        address[] inheritors;
        uint64[] silenceTime;
    }

    uint64 public constant ANNUAL_FEE_PERIOD = 365 days;
    uint8  public constant MAX_COSIGNERS_NUMBER = 100; // Including creator

    // keccak256(abi.encode(uint256(keccak256("ubdn.storage.DeTrustMultisigModel_01")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant DeTrustModelStorageLocation =  0xcf4a3a360b04d36570cb6bdd7ba148570ed50f35bf2cf98d796cd5493321bd00;    
    
    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);
    error NeedMoreValidSignatures(uint8 needMore);
    error CoSignerAlreadyExist(address signer);
    event EtherTransfer(address sender, uint256 amount);

    /**
     * @dev Throws if called by any account other than the creator 
     *  or inheritor after silence time.
     */
    modifier onlyCreatorOrInheritor() {
        _checkCreatorOrInheritor();
        _;
    }

    modifier onlySelfSender(){
        require(_msgSender() == address(this), "Only Self Signed");
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
        __DeTrustModel_01_Executive_init(
            _threshold, _inheritors, _silence,// _name, 
            _feeToken, _feeAmount, _feeBeneficiary, _feePrepaidPeriod
        );
         __EIP712_init("UBDN DeTrust", "0.0.1");

    }

    /**
     * @dev Sets the sender as the initial owner, the beneficiary as the pending owner, 
     * the start timestamp and the
     * vesting duration of the vesting wallet.
     */
    function __DeTrustModel_01_Executive_init(
        uint8 _threshold,
        address[] calldata _inheritors,
        uint64[] calldata  _silence,
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
    ) internal onlyInitializing 
    {
        //__Ownable_init_unchained(_owner);
        __DeTrustModel_01_Executive_init_unchained(
             _threshold, _inheritors, _silence, //_name, 
            _feeToken, _feeAmount, _feeBeneficiary, _feePrepaidPeriod
        );
    }

    function __DeTrustModel_01_Executive_init_unchained(
        uint8 _threshold,
        address[] calldata _inheritors,
        uint64[] calldata  _silence,
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
        
    ) internal onlyInitializing 
    {
        require(_inheritors.length <= MAX_COSIGNERS_NUMBER, "Too much inheritors");
        require(_inheritors.length == _silence.length, "Arrays must be equal");
        require(_threshold <= _inheritors.length, "Not greater then signers count");
        require(_silence[0] == 0, "Cant restrict owners sign");
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        $.lastOwnerOp = block.timestamp;
        $.fee.feeToken = _feeToken;
        $.fee.feeAmount = _feeAmount;
        $.fee.feeBeneficiary = _feeBeneficiary;
        $.fee.payedTill = uint64(block.timestamp) + ANNUAL_FEE_PERIOD + _feePrepaidPeriod;
        $.threshold = _threshold;
        for (uint8 i; i < _inheritors.length; ++ i) {
            $.inheritors.push(_inheritors[i]);
            $.silenceTime.push(_silence[i]);
        }
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
        _updateLastOwnerOp($);
        r = _checkSignaturesAndExecute($, _target, _value, _data, _signatures);
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

    /**
     * @dev Use this method to change multisig threshold. 
     * @param _newThreshold !!! must be greater or equal current cosigners number
     */
    function changeThreshold(uint8 _newThreshold) external onlySelfSender {
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        require(_newThreshold >= $.inheritors.length, "New Threshold less than co-signers count");
        $.threshold = _newThreshold;
    }

    /**
     * @dev Add signer
     * @param _newSigner new signer address
     * @param _newPeriod new signer time param(dends on implementation)
     */ 
    function addSigner(address _newSigner, uint64 _newPeriod) 
        external 
        onlySelfSender
        returns(uint8 signersCount)
    {
        require(_newSigner != address(0), "No Zero address");
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        // increase count for succesfull tx (GAS SAFE)
        signersCount = uint8($.inheritors.length + 1);
        require(signersCount <= MAX_COSIGNERS_NUMBER, "Too much inheritors");

        // check no double
        for (uint256 i = 0; i < signersCount - 1; ++ i) {
            if ($.inheritors[i] == _newSigner) {
                revert CoSignerAlreadyExist(_newSigner);
            }
        }
        $.inheritors.push(_newSigner);
        $.silenceTime.push(_newPeriod);
    }


    
    /**
     * @dev Remove signer with appropriate check
     * @param _signerIndex index of signer address in array
     */ 
    function removeSignerByIndex(uint256 _signerIndex) 
        external  
        returns(uint8 signersCount)
    {
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        // decrease count for succesfull tx (GAS SAFE)
        signersCount = uint8($.inheritors.length - 1);
        require(signersCount >= $.threshold, "New Signers count less then threshold");

        // if deleting index is not last array element then need to replace it with last
        if (_signerIndex != signersCount + 1) {
            $.inheritors[_signerIndex] = $.inheritors[signersCount + 1];
            $.silenceTime[_signerIndex] = $.silenceTime[signersCount + 1];
        }
        $.inheritors.pop();
        $.silenceTime.pop();
    }


    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev Use this method for static call any dApps onchain
     * @param _target address of dApp smart contract
     * @param _data ABI encoded transaction payload
     */
    function staticCallOp(
        address _target,
        bytes memory _data
    ) external view onlyCreatorOrInheritor returns (bytes memory r) {
        r = Address.functionStaticCall(_target, _data);
    }

    /**
     * @dev Returns creator of DeTrust proxy
     */
    function creator() external view returns(address){
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        return $.inheritors[0];
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

    function txDataDigest(
        address _target, 
        uint256 _value, 
        bytes memory _data, 
        uint256 _nonce
    ) internal view returns(bytes32 digest) 
    {
        return _txDataDigest(_target, _value, _data, _nonce);
    }

    ////////////////////////////////////////////////////////////////////////

    /**
     * @dev Refresh last operation timestamp
     */
    function _updateLastOwnerOp(DeTrustModelStorage_01 storage st) internal {
        (bool isIn,) = _isInList(st);
        if (isIn) {
            // if code here hence time condition are OK 
            // and from this moment assete are inherited
            st.inherited = true;
        }

        if (! st.inherited) {
            // update only till inhereted moment
            st.lastOwnerOp = block.timestamp;
        }

    }

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
     * @dev Throws if the sender is not the owner
     *  or inheritor after silence time.
     */
    function _checkCreatorOrInheritor() internal view virtual {
        DeTrustModelStorage_01 storage $ = _getDeTrustModel_01_ExecutiveStorage();
        (bool isInInheritorList, uint256 stm) = _isInList($);
         if (
                ($.inheritors[0] != _msgSender()) && !isInInheritorList
                ||
            (
                  isInInheritorList && (block.timestamp < ($.lastOwnerOp + stm))
            )
        )
        {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function _isInList(DeTrustModelStorage_01 storage st) internal view 
        returns(bool r, uint256 silenceTime_)
    {
        // start from second[1] element because first[0] is crteator
        for (uint256 i = 1; i < st.inheritors.length; ++ i) {
            if (st.inheritors[i] == _msgSender()) {
                r = true;
                silenceTime_ = uint256(st.silenceTime[i]);
                break;
            }
        }
    }

    function _getDeTrustModel_01_ExecutiveStorage() 
        private pure returns (DeTrustModelStorage_01 storage $) 
    {
        assembly {
            $.slot := DeTrustModelStorageLocation
        }
    }

    ////////////////////////////////////////////
    ///////   Multisig internal functions    ///
    ////////////////////////////////////////////
    function _checkSignaturesAndExecute(
        DeTrustModelStorage_01 storage st,
        address _target,
        uint256 _value,
        bytes memory _data,
        bytes[] memory _signatures
    ) internal returns(bytes memory r) {
        bytes32  dgst =_txDataDigest(_target, _value, _data, st.nonce);
        _checkSignaturesForDigest(st, dgst, _signatures);
        r = Address.functionCallWithValue(_target, _data, _value);
        st.nonce ++;

    }
    
    
    function _txDataDigest(
        address _target, 
        uint256 _value, 
        bytes memory _data, 
        uint256 _nonce
    ) internal view returns(bytes32 digest) {
        digest =  _hashTypedDataV4(
            keccak256(abi.encode(_target, _value, keccak256(_data), _nonce))
        );
    }

    function _checkSignaturesForDigest(
        DeTrustModelStorage_01 storage st,
        bytes32 _digest, 
        bytes[] memory _signatures
    ) internal view returns(bool ok)
    {
        TxSingCheck[] memory checkList = new TxSingCheck[](st.inheritors.length);
        // Fill cheklist with signers data for safe gas. Becuase we need compare 
        // all signatures with all records.
        for (uint256 i = 0; i < checkList.length; ++ i){
            checkList[i].signer = st.inheritors[i];
            // !!!! Main signer validity rule  is here
            checkList[i].isValid = _isValidSignerRecord(st, i);
        }
        uint8 thresholdCounter = st.threshold;

        for (uint256 i = 0; i < _signatures.length; ++ i) {
            // recover signer address
            address signedBy = _digest.recover(_signatures[i]); 
            for (uint256 j = 0; j < checkList.length; ++ j) {
                if (
                    // record with exact signer
                    checkList[i].signer == signedBy

                    // no double signs with one saddress
                    && !checkList[i].signOK  

                    // signer is valid to sign tx
                    && checkList[i].isValid
                ) 
                {
                    checkList[i].signOK = true;
                    thresholdCounter --;
                    break;
                }
            }
            if (thresholdCounter == 0) {
                ok = true;
                break; 
            }     
        }
        if (!ok) {
            // Error not enough valid signatures
            revert NeedMoreValidSignatures(thresholdCounter);
        }
    }

    function _isValidSignerRecord(DeTrustModelStorage_01 storage st, uint256 _signerIndex)
        internal
        virtual
        view
        returns(bool valid)
    {
        // !!!! Main signer validity rule  is here
        valid = st.silenceTime[_signerIndex] + st.lastOwnerOp <= block.timestamp;
    } 
}
