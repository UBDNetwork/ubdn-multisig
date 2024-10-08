// SPDX-License-Identifier: MIT
// Onchain Multisig 
pragma solidity 0.8.26;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ContextUpgradeable, Initializable} from "@Uopenzeppelin/contracts/utils/ContextUpgradeable.sol";
import "@Uopenzeppelin/contracts/utils/cryptography/EIP712Upgradeable.sol"; 
 import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 

/**
 * @dev This is abstract contract with ONCHAIN multisig wallet functions
 * Upon creation the address of the heir(s) and  the time for each co-signer
 * after which he(she) will be able to sign tx.  
 * 
 * !!! This is implementation contract for proxy conatract creation
 */
abstract contract MultisigOnchainBase_01 is 
    Initializable, 
    ContextUpgradeable
{

    enum TxStatus {WaitingForSigners, Executed, Rejected}


    struct Signer {
        address signer;
        uint64 validFrom;
    }

    struct Operation {
        address target;
        uint256 value;
        bytes metaTx;
        address[] signedBy;
        TxStatus status;

    }
    /// @custom:storage-location erc7201:ubdn.storage.MultisigOnchainBase_01_Storage
    struct MultisigOnchainBase_01_Storage {
        uint8 threshold;
        Signer[] cosigners;
        Operation[] ops;

    }

    uint8  public constant MAX_COSIGNERS_NUMBER = 100; // Including creator

    // keccak256(abi.encode(uint256(keccak256("ubdn.storage.MultisigOnchainBase_01_Storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MultisigOnchainBase_01_StorageLocation =  0xf486b49c0fd95e99c95d211c0814e0c85bb59e07a1a40077b7a34b255b307200;    
    
    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    //error OwnableUnauthorizedAccount(address account);
    
    error ActionDeniedForThisStatus(TxStatus status);
    error CoSignerAlreadyExist(address signer);
    error CoSignerNotValid(address signer);
    error CoSignerNotExist(address signer);
    error ExecutionDenied(TxStatus status, uint8 signaturesNumber);

    event SignatureAdded(uint256 indexed nonce, address signer, uint256 totalSignaturesCollected);
    event SignatureRevoked(uint256 indexed nonce, address signer, uint256 totalSignaturesCollected);
    event TxExecuted(uint256 indexed nonce, address sender);
    event TxRejected(uint256 indexed nonce, address sender);
    event SignerAdded(Signer signer, uint8 newCosignersNumber);
    event SignerRemoved(Signer signer, uint8 newCosignersNumber);
    event SignerChanged(address  signer, uint64 oldDate, uint64 newDate);
    event ThresholdChanged(uint8 thresholdOld, uint8 thresholdNew);

    event EtherTransfer(address sender, uint256 value);

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

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {
        emit EtherTransfer(msg.sender, msg.value);
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
        __MultisigOnchainBase_01_init(
            _threshold, _cosignersAddresses, _validFrom
        );
         __EIP712_init("Iber Onchain Multisig", "0.0.1");

    }
    */

    function __MultisigOnchainBase_01_init(
        uint8 _threshold,
        address[] memory _cosignersAddresses,
        uint64[] memory  _validFrom
    ) internal onlyInitializing 
    {
        __MultisigOnchainBase_01_init_unchained(
             _threshold, _cosignersAddresses, _validFrom
        );
    }

    
    /**
     * @dev Main init functionality
     */
    function __MultisigOnchainBase_01_init_unchained(
        uint8 _threshold,
        address[] memory _cosignersAddresses,
        uint64[] memory  _validFrom
        
    ) internal onlyInitializing 
    {
        require(_cosignersAddresses.length <= MAX_COSIGNERS_NUMBER, "Too much inheritors");
        require(_cosignersAddresses.length == _validFrom.length, "Arrays must be equal");
        require(_threshold <= _cosignersAddresses.length, "Not greater then signers count");
        require(_cosignersAddresses.length >= 2, "At least two signers");
        //require(_cosignersAddresses.length > 1, "At least one signer");
        require(_threshold > 0 , "No zero threshold");

        // Check for no doubles
        for (uint256 i = 0; i < _cosignersAddresses.length; ++ i) {
            for (uint256 j = i + 1; j < _cosignersAddresses.length; ++ j){
                require(_cosignersAddresses[i] != _cosignersAddresses[j],
                    "No double cosigners"
                );
            }
        }

        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        $.threshold = _threshold;
        for (uint8 i; i < _cosignersAddresses.length; ++ i) {
            require(_cosignersAddresses[i] != address(0), "No Zero address");
            $.cosigners.push(Signer(_cosignersAddresses[i], _validFrom[i]));
        }
    }

    /**
     * @dev Storage Getter for access contract state
     */
    function _getMultisigOnchainBase_01_Storage() 
        private pure returns (MultisigOnchainBase_01_Storage storage $) 
    {
        assembly {
            $.slot := MultisigOnchainBase_01_StorageLocation
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Use this method to change multisig threshold. 
     * @param _newThreshold !!! must be less or equal current cosigners number
     */
    function changeThreshold(uint8 _newThreshold) external onlySelfSender {
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();

        require(_newThreshold <= $.cosigners.length, "New Threshold more than co-signers count");
        require(_newThreshold > 0 , "No zero threshold");
        emit ThresholdChanged($.threshold, _newThreshold);
        $.threshold = _newThreshold;

    }

    /**
     * @dev Add signer
     * @param _newSigner new signer address
     * @param _newPeriod new signer time param(dends on implementation)
     */ 
    function addSigner(address _newSigner, uint64 _newPeriod) 
        public
        virtual 
        onlySelfSender
        returns(uint8 signersCount)
    {
        require(_newSigner != address(0), "No Zero address");
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        
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
        emit SignerAdded(Signer(_newSigner, _newPeriod), signersCount);
    }

    function editSignerDate(address _coSigner, uint64 _newPeriod) 
        public 
        virtual
        onlySelfSender
    {
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        
        // check no double
        for (uint256 i = 0; i < $.cosigners.length - 1; ++ i) {
            if ($.cosigners[i].signer == _coSigner) {
                require(i != 0, "Cant edit owner's period");
                emit SignerChanged(_coSigner,  $.cosigners[i].validFrom, _newPeriod);
                $.cosigners[i].validFrom = _newPeriod;
            }
        }
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
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        // decrease count for succesfull tx (GAS SAFE)
        signersCount = uint8($.cosigners.length - 1);
        require(signersCount >= $.threshold, "New Signers count less then threshold");
        require(_signerIndex != 0, "Cant remove multisig owner(creator)");
        emit SignerRemoved($.cosigners[_signerIndex], signersCount);
        // if deleting index is not last array element then need to replace it with last
        if (_signerIndex != signersCount + 1) {
            // Because signersCount already decreased it already equal to last array element
            $.cosigners[_signerIndex] = $.cosigners[signersCount];
        }
        $.cosigners.pop();
    }
    
    /**  
     * @dev Use this method for save metaTx and make first signature onchain
     * @param _target address of dApp smart contract
     * @param _value amount of native token in tx(msg.value)
     * @param _data ABI encoded transaction payload
     */
    function createAndSign(
        address _target,
        uint256 _value,
        bytes memory _data
    ) 
        public
        virtual
        returns(uint256 nonce_)
    {
        nonce_ = _createOp(_target, _value, _data);
        _hookCheckSender(_msgSender());
    } 

    /**  
     * @dev Use this method for sign metaTx onchain and execute as well
     * @param _nonce index of saved Meta Tx
     * @param _execWhenReady if true then tx will be executed if all signatures are collected
     */
    function signAndExecute(uint256 _nonce, bool _execWhenReady) 
        public
        virtual 
        returns(uint256 signedByCount) 
    {
        signedByCount = _signMetaTx(_nonce,_execWhenReady);
        _hookCheckSender(_msgSender());
    }

    /**  
     * @dev Use this method for execute tx
     * @param _nonce index of saved Meta Tx
     */
    function executeOp(uint256 _nonce) public virtual returns(bytes memory r){
        r = _execTx(_nonce);
        _hookCheckSender(_msgSender());
    }

    /**  
     * @dev Use this method for  execute batch of well signed tx
     * @param _nonces index of saved Meta Tx
     */
    function executeOp(uint256[] memory _nonces) public virtual returns(bytes memory r){
        for (uint256 i = 0; i < _nonces.length; ++ i){
            r = _execTx(_nonces[i]);
        }
        _hookCheckSender(_msgSender());
    }

    /**  
     * @dev Use this method for  revoke signature onchain and reject as well
     * @param _nonce index of saved Meta Tx
     * @param _rejectWhenReady if true then tx will be rejected if all signatures revoked
     */
    function revokeSignature(uint256 _nonce, bool _rejectWhenReady) 
        public 
        returns(uint256 signedByCount) 
    {
        signedByCount = _revokeSignature(_nonce, _msgSender(), _rejectWhenReady);
        _hookCheckSender(_msgSender());
    }

    /**  
     * @dev Use this method for  reject tx
     * @param _nonce index of saved Meta Tx
     */
    function rejectTx(uint256 _nonce) public {
        _rejectTx(_nonce);
        _hookCheckSender(_msgSender());
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
    function getMultisigOnchainBase_01() 
        public 
        pure
        returns(MultisigOnchainBase_01_Storage memory msig)
    {
        msig = _getMultisigOnchainBase_01_Storage();
    }


    function getMultisigSettings() 
        public 
        view 
        returns(uint8 thr, Signer[] memory sgs)
    {
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        thr = $.threshold;
        sgs = $.cosigners;
    }

    function getMultisigOpByNonce(uint256 _nonce)  
        public 
        view 
        returns(Operation memory op)
    {
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        op = $.ops[_nonce];
    } 

    function getMultisigLastNonce()  
        public 
        view 
        returns(uint256 nonce)
    {
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        nonce = $.ops.length;
        // Actually it is not nonce  yet but array length
        require(nonce > 0, "No Operations yet"); 
        nonce -= 1;
    }
    ////////////////////////////////////////////
    ///////   Multisig internal functions    ///
    ////////////////////////////////////////////
    function _createOp(
        address _target,
        uint256 _value,
        bytes memory _data
    )
        internal
        returns(uint256 nonce_)
    {
        require(_target != address(0), "No Zero Address");
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        Operation storage op = $.ops.push();
        op.target = _target;
        op.value = _value;
        op.metaTx = _data;
        // Next asignment is not necessery because default var value
        // op.status = TxStatus.WaitingForSigners 
        nonce_ = $.ops.length -1;
        //Signer[] storage _sgnrs = $.cosigners;
        _checkSigner(_msgSender(), $.cosigners);
        _signMetaTxOp(op, _msgSender());
        emit SignatureAdded(nonce_, _msgSender(), 1);
    }

    function _signMetaTxOp(
         Operation storage _op, 
        address _signer
    ) 
        internal
        returns (uint256 signedByCount) 
    {
        if (_op.status != TxStatus.WaitingForSigners) {
            revert ActionDeniedForThisStatus(_op.status); 
        }
        // Check that not signed before
        for (uint256 i; i < _op.signedBy.length; ++ i) {
            if (_op.signedBy[i] == _signer) {
                revert CoSignerAlreadyExist(_signer);
            }
        }
        _op.signedBy.push(_signer);
        signedByCount = _op.signedBy.length; 
    }

    function _signMetaTx(uint256 _nonce, bool _execWhenReady) 
        internal
        returns (uint256 signedByCount) 
    {
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        _checkSigner(_msgSender(), $.cosigners);
        signedByCount = _signMetaTxOp($.ops[_nonce], _msgSender());
        emit SignatureAdded(_nonce, _msgSender(), signedByCount);
        if (_execWhenReady &&  signedByCount == $.threshold){
            _execOp($.ops[_nonce], $.threshold);
            emit TxExecuted(_nonce, _msgSender());
        }

    }

    function _execTx(uint256 _nonce) internal returns(bytes memory r) {
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        r =  _execOp($.ops[_nonce], $.threshold);
        emit TxExecuted(_nonce, _msgSender());
    }

    function _execOp(Operation storage _op, uint8 _threshold) 
        internal 
        returns(bytes memory r)
    {
        if (
               _op.status == TxStatus.WaitingForSigners 
               && _op.signedBy.length >= _threshold
        ) 
        {
            if (keccak256(bytes("")) == keccak256(_op.metaTx)) {
                // JUST sending ether, no call methods
                Address.sendValue(payable(_op.target), _op.value);
            } else {
                r = Address.functionCallWithValue(
                    _op.target, 
                    _op.metaTx, 
                    _op.value
                );

            }
              
            _op.status = TxStatus.Executed; 
        } else {
            revert ExecutionDenied(_op.status, uint8(_op.signedBy.length));
        }
    }

    function _rejectTx(uint256 _nonce) internal {
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        _rejectOp($.ops[_nonce]);
        emit TxRejected(_nonce, _msgSender());
    }

    function _rejectOp(Operation storage _op) internal {
        if (_op.status == TxStatus.WaitingForSigners  && _op.signedBy.length == 0){
            _op.status = TxStatus.Rejected;
        } else {
            revert ActionDeniedForThisStatus(_op.status);
        }

    }
    function _revokeSignature(uint256 _nonce, address _signer, bool _rejectWhenReady) 
        internal
        returns(uint256 signedByCount)
    {
        MultisigOnchainBase_01_Storage storage $ = _getMultisigOnchainBase_01_Storage();
        // TODO GAS saving
        if ($.ops[_nonce].status == TxStatus.WaitingForSigners){
            for(uint256 i = 0; i < $.ops[_nonce].signedBy.length; ++ i){
                if ($.ops[_nonce].signedBy[i] == _signer) {
                    if (i != $.ops[_nonce].signedBy.length -1){
                        $.ops[_nonce].signedBy[i] = $.ops[_nonce].signedBy[$.ops[_nonce].signedBy.length -1];
                    }
                    $.ops[_nonce].signedBy.pop();
                } 
            }
        } else {
            revert ActionDeniedForThisStatus($.ops[_nonce].status);
        }
        
        signedByCount = $.ops[_nonce].signedBy.length;
        emit SignatureRevoked(_nonce, _signer, signedByCount);

        if (_rejectWhenReady && signedByCount == 0) {
            _rejectOp($.ops[_nonce]);
            emit TxRejected(_nonce, _msgSender());
        }
    }

    function _checkSigner(
        address _signer, 
        Signer[] storage _cosigners
    ) 
       internal 
       view
    {
        for (uint256 i = 0; i < _cosigners.length; ++ i) {
            if (_cosigners[i].signer == _signer) {
                // Use this hook for ability to change logic in inheritors
                if (_isValidSignerRecord(_cosigners[i])){
                    return;
                } else {
                    revert CoSignerNotValid(_signer);
                }
            }
        }
        revert CoSignerNotExist(_signer);
    }

  

    function _isValidSignerRecord(
        //MultisigOnchainBase_01_Storage storage st, 
        Signer storage _cosigner
    )
        internal
        virtual
        view
        returns(bool valid)
    {
        // !!!! Main signer validity rule  is here
        valid = _cosigner.validFrom <= block.timestamp;
    } 

    function _hookCheckSender(address _sender) internal virtual {
        _sender;
    }

}
