// SPDX-Licence-Identifier: MIT
// UBD Network DeTrustMultisigOnchainModel_Free
pragma solidity 0.8.26;

import "./MultisigOnchainBase_01.sol";

/**
 * @dev This is a  trust model onchain multisig implementation.
 * Upon creation the addresses of the heirs(co-signers) could be set
 * 
 * !!! This is implementation contract for proxy conatract creation
 */
contract DeTrustMultisigOnchainModel_Free is MultisigOnchainBase_01 {

    
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
        
        // supress solc warnings
        _validFrom;
        _feeToken;
        _feeAmount;
        _feeBeneficiary;
        _feePrepaidPeriod;

        // in this model all _validFrom must be zero so just replace 
        // original with zero array
        uint64[] memory dummyArray = new uint64[](_cosignersAddresses.length);
        __MultisigOnchainBase_01_init(
            _threshold, _cosignersAddresses, dummyArray
        );
    }


    /**
     * @dev Add signer
     * @param _newSigner new signer address
     * @param _newPeriod new signer time param(dends on implementation)
     */ 
    function addSigner(address _newSigner, uint64 _newPeriod) 
        public
        override 
        returns(uint8 signersCount)
    {
        _newPeriod;
        return super.addSigner(_newSigner, uint64(0));
    }

    function editSignerDate(address _coSigner, uint64 _newPeriod) 
        public 
        pure
        override
    {
        _coSigner;
        _newPeriod;
        revert("Disable in this model");
    }

}