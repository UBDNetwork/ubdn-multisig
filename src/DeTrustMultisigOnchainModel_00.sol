// SPDX-Licence-Identifier: MIT
// UBD Network DeTrustMultisigOnchainModel_00
pragma solidity 0.8.26;

import "./MultisigOnchainBase_01.sol";
import "./FeeManager_01.sol";

/**
 * @dev This is a  trust model onchain multisig implementation.
 * Upon creation the addresses of the heirs(co-signers) and 
 * the time (T) from each cosigner can sign transactios. 
 * 
 * !!! This is implementation contract for proxy conatract creation
 */
contract DeTrustMultisigOnchainModel_00 is MultisigOnchainBase_01, FeeManager_01 {

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
        require(_validFrom[0] == 0, "Owner must be always able to sign");
        __MultisigOnchainBase_01_init(
            _threshold, _cosignersAddresses, _validFrom
        );

        __FeeManager_01_init(
            _feeToken, _feeAmount, _feeBeneficiary, _feePrepaidPeriod
        );
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

}