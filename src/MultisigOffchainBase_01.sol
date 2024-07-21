// SPDX-License-Identifier: MIT
// Offchain Multisig 
pragma solidity 0.8.26;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ContextUpgradeable, Initializable} from "@Uopenzeppelin/contracts/utils/ContextUpgradeable.sol";
import "@Uopenzeppelin/contracts/utils/cryptography/EIP712Upgradeable.sol"; 
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 

/**
 * @dev This is abstract contract with multisig wallet functions
 * Upon creation the address of the heir(s) and 
 * the time (dT) of the owner’s absence(silence) are passed. When the heir 
 * applies, this time of inactivity of the owner will be checked. If it is 
 * greater than dT, then both the creator and the heir have access 
 * to the wallet's assets. 
 * 
 * !!! This is implementation contract for proxy conatract creation
 */
abstract contract MultisigOffchainBase_01 is 
    Initializable, 
    ContextUpgradeable,
    EIP712Upgradeable
{
    using ECDSA for bytes32;


    struct TxSingCheck {
        address signer;
        bool isValid;
        bool signOK;
    }

    struct Signer {
        address signer;
        uint64 validFrom;
    }
    /// @custom:storage-location erc7201:ubdn.storage.MultisigOffchainBase_01_Storage
    struct MultisigOffchainBase_01_Storage {
        uint256 nonce;
        uint8 threshold;
        Signer[] cosigners;
    }

    uint8  public constant MAX_COSIGNERS_NUMBER = 100; // Including creator

    // keccak256(abi.encode(uint256(keccak256("ubdn.storage.MultisigOffchainBase_01_Storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MultisigOffchainBase_01_StorageLocation =  0x352c9f4bb0ce8c9559df4b522a6d98fb537f83bfef0351c2d8e56b58bc614b00;    
    
    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    //error OwnableUnauthorizedAccount(address account);
    error NeedMoreValidSignatures(uint8 needMore);
    error CoSignerAlreadyExist(address signer);

    /**
     * @dev Throws if called by any account other than this contract or proxy
     */
    modifier onlySelfSender(){
        require(_msgSender() == address(this), "Only Self Signed");
        _;
    }

    constructor() {
      _disableInitializers();
    }

    /////////////////////////////////////////////////////
    /// OpenZepelin Pattern for Proxy initialize      ///
    /////////////////////////////////////////////////////

    /*
    // This is initializer code example. Must be implemented once in inheritor

    function initialize(
        uint8 _threshold,
        address[] calldata _cosignersAddresses,
        uint64[] calldata _validFrom
       
    ) public initializer
    {
        __MultisigOffchainBase_01_init(
            _threshold, _cosignersAddresses, _validFrom
        );
         __EIP712_init("Iber Offchain Multisig", "0.0.1");

    }
    */

    function __MultisigOffchainBase_01_init(
        uint8 _threshold,
        address[] calldata _cosignersAddresses,
        uint64[] calldata  _validFrom
    ) internal onlyInitializing 
    {
        __MultisigOffchainBase_01_init_unchained(
             _threshold, _cosignersAddresses, _validFrom
        );
    }

    
    /**
     * @dev Main init functionality
     */
    function __MultisigOffchainBase_01_init_unchained(
        uint8 _threshold,
        address[] calldata _cosignersAddresses,
        uint64[] calldata  _validFrom
        
    ) internal onlyInitializing 
    {
        require(_cosignersAddresses.length <= MAX_COSIGNERS_NUMBER, "Too much inheritors");
        require(_cosignersAddresses.length == _validFrom.length, "Arrays must be equal");
        require(_threshold <= _cosignersAddresses.length, "Not greater then signers count");
        //require(_validFrom[0] == 0, "Cant restrict owners sign");
        MultisigOffchainBase_01_Storage storage $ = _getMultisigOffchainBase_01_Storage();
        $.threshold = _threshold;
        for (uint8 i; i < _cosignersAddresses.length; ++ i) {
            $.cosigners.push(Signer(_cosignersAddresses[i], _validFrom[i]));
        }
    }

    /**
     * @dev Storage Getter for access contract state
     */
    function _getMultisigOffchainBase_01_Storage() 
        internal pure returns (MultisigOffchainBase_01_Storage storage $) 
    {
        assembly {
            $.slot := MultisigOffchainBase_01_StorageLocation
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Use this method to change multisig threshold. 
     * @param _newThreshold !!! must be greater or equal current cosigners number
     */
    function changeThreshold(uint8 _newThreshold) external onlySelfSender {
        MultisigOffchainBase_01_Storage storage $ = _getMultisigOffchainBase_01_Storage();
        require(_newThreshold >= $.cosigners.length, "New Threshold less than co-signers count");
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
        MultisigOffchainBase_01_Storage storage $ = _getMultisigOffchainBase_01_Storage();
        
        // increase count for succesfull tx (GAS SAFE)
        signersCount = uint8($.cosigners.length + 1);
        require(signersCount <= MAX_COSIGNERS_NUMBER, "Too much inheritors");

        // check no double
        for (uint256 i = 0; i < signersCount - 1; ++ i) {
            if ($.cosigners[i].signer == _newSigner) {
                revert CoSignerAlreadyExist(_newSigner);
            }
        }
        $.cosigners.push(Signer(_newSigner, _newPeriod));
    }


    
    /**
     * @dev Remove signer with appropriate check
     * @param _signerIndex index of signer address in array
     */ 
    function removeSignerByIndex(uint256 _signerIndex) 
        external
        onlySelfSender  
        returns(uint8 signersCount)
    {
        MultisigOffchainBase_01_Storage storage $ = _getMultisigOffchainBase_01_Storage();
        // decrease count for succesfull tx (GAS SAFE)
        signersCount = uint8($.cosigners.length - 1);
        require(signersCount >= $.threshold, "New Signers count less then threshold");

        // if deleting index is not last array element then need to replace it with last
        if (_signerIndex != signersCount + 1) {
            $.cosigners[_signerIndex] = $.cosigners[signersCount + 1];
        }
        $.cosigners.pop();
    }
    

    /**   EXAMPLE METHOD FOR IMPLEMENT IN INHERITOR
     * @dev Use this method for interact any dApps onchain
     * @param _target address of dApp smart contract
     * @param _value amount of native token in tx(msg.value)
     * @param _data ABI encoded transaction payload
     */
    // function executeOp(
    //     address _target,
    //     uint256 _value,
    //     bytes memory _data,
    //     bytes[] memory _signatures
    // ) public returns (bytes memory r) {
    //     MultisigOffchainBase_01_Storage storage $ = _getMultisigOffchainBase_01_Storage();
    //     r = _checkSignaturesAndExecute($, _target, _value, _data, _signatures);
    // }

    /**     EXAMPLE METHOD FOR IMPLEMENT IN INHERITOR
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
    // function executeMultiOp(
    //     address[] calldata _targetArray,
    //     uint256[] calldata _valueArray,
    //     bytes[] memory _dataArray,
    //     bytes[][] memory _signaturesArray
    // ) external  returns (bytes[] memory r) {
    //     r = new bytes[](_dataArray.length);
    //     for (uint256 i = 0; i < _dataArray.length; ++ i){
    //         r[i] =executeOp(_targetArray[i], _valueArray[i], _dataArray[i], _signaturesArray[i]);
    //     }
    // }
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev Use this method for static call any dApps onchain
     * @param _target address of dApp smart contract
     * @param _data ABI encoded transaction payload
     */
    function staticCallOp(
        address _target,
        bytes memory _data
    )   
        external 
        view  
        virtual 
        returns (bytes memory r) 
    {
        r = Address.functionStaticCall(_target, _data);
    }


    /**
     * @dev Returns full Multisig info
     */
    function getMultisigOffchainBase_01() 
        public 
        pure
        virtual 
        returns(MultisigOffchainBase_01_Storage memory msig)
    {
        msig = _getMultisigOffchainBase_01_Storage();
    }

   

    function txDataDigest(
        address _target, 
        uint256 _value, 
        bytes memory _data, 
        uint256 _nonce
    ) internal view virtual returns(bytes32 digest) 
    {
        return _txDataDigest(_target, _value, _data, _nonce);
    }

    function isSignerValid(address _signer) 
        public 
        view 
        returns(bool isValid, uint256 validFrom_) 
    {
        MultisigOffchainBase_01_Storage memory $ = _getMultisigOffchainBase_01_Storage();
        // TODO tru optomize GAS
        for (uint256 i = 0; i < $.cosigners.length; ++ i) {
            if ($.cosigners[i].signer == _signer) {
                isValid = _isValidSignerRecord($.cosigners, i);
                validFrom_ = $.cosigners[i].validFrom;
                break;
            }
        }

    }
    ////////////////////////////////////////////////////////////////////////
    // TODO  Remove
    function _isSignerInList(MultisigOffchainBase_01_Storage storage st) internal view virtual
        returns(bool r, uint256 validFrom_)
    {
        for (uint256 i = 0; i < st.cosigners.length; ++ i) {
            if (st.cosigners[i].signer == _msgSender()) {
                r = true;
                validFrom_ = uint256(st.cosigners[i].validFrom);
                break;
            }
        }
    }



    ////////////////////////////////////////////
    ///////   Multisig internal functions    ///
    ////////////////////////////////////////////
    function _checkSignaturesAndExecute(
        //MultisigOffchainBase_01_Storage storage st,
        address _target,
        uint256 _value,
        bytes memory _data,
        bytes[] memory _signatures
    ) internal returns(bytes memory r) {
        MultisigOffchainBase_01_Storage storage $ = _getMultisigOffchainBase_01_Storage();
        bytes32  dgst =_txDataDigest(_target, _value, _data, $.nonce);
        _checkSignaturesForDigest($, dgst, _signatures);
        $.nonce ++;
        r = Address.functionCallWithValue(_target, _data, _value);
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
        MultisigOffchainBase_01_Storage storage st,
        bytes32 _digest, 
        bytes[] memory _signatures
    ) internal  returns(bool ok)
    {
        TxSingCheck[] memory checkList = new TxSingCheck[](st.cosigners.length);
        // Fill cheklist with signers data for safe gas. Becuase we need compare 
        // all signatures with all records.
        for (uint256 i = 0; i < checkList.length; ++ i){
            checkList[i].signer = st.cosigners[i].signer;
            // !!!! Main signer validity rule  is here
            checkList[i].isValid = _isValidSignerRecord(st.cosigners, i);
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
                    _hookValidSiner(j,checkList[i].signer, i, thresholdCounter);
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

    function _isValidSignerRecord(
        //MultisigOffchainBase_01_Storage storage st, 
        Signer[] memory _cosigners,
        uint256 _signerIndex
    )
        internal
        virtual
        view
        returns(bool valid)
    {
        // !!!! Main signer validity rule  is here
        //valid = st.silenceTime[_signerIndex] + st.lastOwnerOp <= block.timestamp;
        valid = _cosigners[_signerIndex].validFrom <= block.timestamp;
    } 

    // For use in inheritors code  
    function _hookValidSiner(
        uint256 _signerIndex,
        address _signerAddress,
        uint256 _signatureIndex, 
        uint8   _thresholdCounter
    ) internal virtual {}
}
