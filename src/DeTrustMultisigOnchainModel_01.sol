// SPDX-Licence-Identifier: MIT
// UBD Network DeTrustMultisigOnchainModel_00
pragma solidity 0.8.26;

import "./MultisigOnchainBase_01.sol";
import "./FeeManager_01.sol";

/**
 * @dev This is a  trust model onchain multisig implementation.
 * In this model all  signers can sign transcation only after dT 
 * since last owner operation. Consider to take this dT upon init 
 * from second _validFrom array element
 * 
 * !!! This is implementation contract for proxy conatract creation
 */
contract DeTrustMultisigOnchainModel_01 is MultisigOnchainBase_01, FeeManager_01 {

   
 /// @custom:storage-location erc7201:ubdn.storage.DeTrustMultisigOnchainModel_01_Storage
    struct DeTrustMultisigOnchainModel_01_Storage {
        uint64 lastOwnerOp;
        uint64 silenceTime;


    }

    // keccak256(abi.encode(uint256(keccak256("ubdn.storage.DeTrustMultisigOnchainModel_01_Storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant DeTrustMultisigOnchainModel_01_StorageLocation =  0x0ab8e5a8f1184da70ff91b7fdffb8fcc2c72e7eca42abeaaffb61154353ccc00;    

   /////////////////////////////////////////////////////
    /// OpenZepelin Pattern for Proxy initialize      ///
    /////////////////////////////////////////////////////
    function initialize(
        uint8 _threshold,
        address[] memory _cosignersAddresses,
        uint64[] memory _validFrom,
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary,
        uint64 _feePrepaidPeriod
       
    ) public initializer
    {
        // require(_validFrom[0] == 0, "Owner must be always able to sign");
        // In this model all  signers can sign transcation only after dT since last owner operation 
        // Consider to take this dT upon init from second _validFrom array element
        DeTrustMultisigOnchainModel_01_Storage storage $ = _getDeTrustMultisigOnchainModel_01_Storage();
        $.lastOwnerOp = uint64(block.timestamp);
        $.silenceTime = _validFrom[1];
        

        __MultisigOnchainBase_01_init(
            _threshold, _cosignersAddresses, _validFrom
        );

        __FeeManager_01_init(
            _feeToken, _feeAmount, _feeBeneficiary, _feePrepaidPeriod
        );

        

    }
    
    /**
     * @dev Storage Getter for access contract state
     */
    function _getDeTrustMultisigOnchainModel_01_Storage() 
        private pure returns (DeTrustMultisigOnchainModel_01_Storage storage $) 
    {
        assembly {
            $.slot := DeTrustMultisigOnchainModel_01_StorageLocation
        }
    }

    /**
     * @dev edit silence interval after which signers will be able sign 
     * and exec tx
     */
    function editSilenceTime(uint64 _newPeriod) 
        external    
        onlySelfSender
    {
        DeTrustMultisigOnchainModel_01_Storage storage $ = _getDeTrustMultisigOnchainModel_01_Storage();
        $.silenceTime = _newPeriod;  
    }

    /**
     * @dev Just for update checkpoint of creator activity
     */
    function iAmAlive() external  {
        DeTrustMultisigOnchainModel_01_Storage storage $ = _getDeTrustMultisigOnchainModel_01_Storage();
        require(
            msg.sender == getMultisigOnchainBase_01().cosigners[0].signer,
            "Only for creator"
        );
        $.lastOwnerOp = uint64(block.timestamp);

    }

    /**  
     * @dev Use this method for sign metaTx onchain and execute as well
     * @param _nonce index of saved Meta Tx
     * @param _execWhenReady if true then tx will be executed if all signatures are collected
     */
    function signAndExecute(uint256 _nonce, bool _execWhenReady) 
        public
        override 
        returns(uint256 signedByCount) 
    {
        _chargeFee(0);
        signedByCount = super.signAndExecute(_nonce, _execWhenReady);
    }

    /**  
     * @dev Use this method for execute tx
     * @param _nonce index of saved Meta Tx
     */
    function executeOp(uint256 _nonce) public override returns(bytes memory r){
        _chargeFee(0);
        r = super.executeOp(_nonce);
    }

    /**  
     * @dev Use this method for  execute batch of well signed tx
     * @param _nonces index of saved Meta Tx
     */
    function executeOp(uint256[] memory _nonces) public override returns(bytes memory r){
        _chargeFee(0);
        r = super.executeOp(_nonces);
    }   


    /**  
     * @dev Use this method for pay in advance any periods. Available only 
     * for trust owner or inheritor
     * @param _numberOfPeriods to pay fee in advance
     */
    function payFeeAdvance(uint64 _numberOfPeriods) external onlySelfSender{
        _chargeFee(_numberOfPeriods);
    }

    /** 
     * @dev Use this method for  charge fee debt if exist. Available for 
     * any address, for example platform owner
     */
    function chargeAnnualFee() external  {
        _chargeFee(0);
    }

    /**
     * @dev Returns full Multisig info
     */
    function getDeTrustMultisigOnchainModel_01() 
        public 
        pure
        returns(DeTrustMultisigOnchainModel_01_Storage memory msig)
    {
        msig = _getDeTrustMultisigOnchainModel_01_Storage();
    }
    
    ///////////////////////////////////////////////////////
    // Overide som from parent for change model behavior //
    ///////////////////////////////////////////////////////

    function editSignerDate(address _coSigner, uint64 _newPeriod) 
        public 
        view
        override
        onlySelfSender
    {
        _coSigner;
        _newPeriod;
        revert("Disable in this model");
    }
    
    // Check ability to sign
    function _isValidSignerRecord(
        Signer storage _cosigner
    )
        internal
        override
        view
        returns(bool valid)
    {
        // !!!! Main signer validity rule  is here
        MultisigOnchainBase_01_Storage memory parent = getMultisigOnchainBase_01();
        // this check is not for owner
        if (parent.cosigners[0].signer != _cosigner.signer){
            DeTrustMultisigOnchainModel_01_Storage memory $ = _getDeTrustMultisigOnchainModel_01_Storage();
            valid = $.lastOwnerOp  + $.silenceTime <= block.timestamp;
        } else {
            valid = true;
        }
    }

    // Overiding hook for update Last Owner Op
    function _hookCheckSender(address _sender) internal override {

        // TODO chek gas , memory to storage
        MultisigOnchainBase_01_Storage memory parent = getMultisigOnchainBase_01();
        if (parent.cosigners[0].signer == _sender){
            DeTrustMultisigOnchainModel_01_Storage storage $ = _getDeTrustMultisigOnchainModel_01_Storage();
            $.lastOwnerOp = uint64(block.timestamp);
        }
    } 

}