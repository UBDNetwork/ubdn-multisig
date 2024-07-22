// SPDX-Licence-Identifier: MIT
// MOck
pragma solidity 0.8.26;

import "../MultisigOffchainBase_01.sol";

contract MockSimpleMultisig is MultisigOffchainBase_01 {

    /////////////////////////////////////////////////////
    /// OpenZepelin Pattern for Proxy initialize      ///
    /////////////////////////////////////////////////////
    function initialize(
        uint8 _threshold,
        address[] calldata _cosignersAddresses,
        uint64[] calldata _validFrom
       
    ) public initializer
    {
        __MultisigOffchainBase_01_init(
            _threshold, _cosignersAddresses, _validFrom
        );
         __EIP712_init("UBDN DeTrust Offchain Multisig", "0.0.1");

    }

     /**   EXAMPLE METHOD FOR IMPLEMENT IN INHERITOR
     * @dev Use this method for interact any dApps onchain
     * @param _target address of dApp smart contract
     * @param _value amount of native token in tx(msg.value)
     * @param _data ABI encoded transaction payload
     */
    function executeOp(
        address _target,
        uint256 _value,
        bytes memory _data,
        bytes[] memory _signatures,
        HashDataType _hashDataType
    ) public returns (bytes memory r) {
        //MultisigOffchainBase_01_Storage storage $ = _getMultisigOffchainBase_01_Storage();
        r = _checkSignaturesAndExecute(_target, _value, _data, _signatures, _hashDataType);
    }

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
    function executeMultiOp(
        address[] calldata _targetArray,
        uint256[] calldata _valueArray,
        bytes[] memory _dataArray,
        bytes[][] memory _signaturesArray,
        HashDataType _hashDataType
    ) external  returns (bytes[] memory r) {
        r = new bytes[](_dataArray.length);
        for (uint256 i = 0; i < _dataArray.length; ++ i){
            r[i] =executeOp(_targetArray[i], _valueArray[i], _dataArray[i], _signaturesArray[i], _hashDataType);
        }
    }


}