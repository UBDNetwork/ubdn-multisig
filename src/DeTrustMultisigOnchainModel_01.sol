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
        require(_validFrom[0] == 0, "Owner must be always able to sign");
        // In this model all  signers can sign transcation only after dT since last owner operation 
        // Consider to take this dT upon init from second _validFrom array element
        DeTrustMultisigOnchainModel_01_Storage storage $ = _getDeTrustMultisigOnchainModel_01_Storage();
        $.lastOwnerOp = uint64(block.timestamp);
        $.silenceTime = _validFrom[1];
        // Set all signers validFrom to same dT
        for (uint256 i = 2; i < _validFrom.length -1; ++ i) {
            _validFrom[i] = _validFrom[1];
        }

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

    function editSilenceTime(uint64 _newPeriod) 
        external    
        onlySelfSender
    {
        DeTrustMultisigOnchainModel_01_Storage storage $ = _getDeTrustMultisigOnchainModel_01_Storage();
        $.silenceTime = _newPeriod;  
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
        DeTrustMultisigOnchainModel_01_Storage memory $ = _getDeTrustMultisigOnchainModel_01_Storage();
        valid = _cosigner.validFrom  + $.silenceTime <= block.timestamp;
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