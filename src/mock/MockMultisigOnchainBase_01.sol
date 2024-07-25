// SPDX-Licence-Identifier: MIT
// MOck
pragma solidity 0.8.26;

import "../MultisigOnchainBase_01.sol";

contract MockMultisigOnchainBase_01 is MultisigOnchainBase_01 {

    /////////////////////////////////////////////////////
    /// OpenZepelin Pattern for Proxy initialize      ///
    /////////////////////////////////////////////////////
    function initialize(
        uint8 _threshold,
        address[] calldata _cosignersAddresses,
        uint64[] calldata _validFrom
       
    ) public initializer
    {
        __MultisigOnchainBase_01_init(
            _threshold, _cosignersAddresses, _validFrom
        );

    }

}