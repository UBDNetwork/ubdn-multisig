// SPDX-License-Identifier: MIT
// UBD Network

pragma solidity 0.8.26;

/**
 * @dev Interface of the DeTrustMultisigModelRegistry.
 */
interface IUsersDeTrustRegistry {

    /**
     * @dev Returns `true` if after trust registered or revert with reason
     */
    function registerTrust(address _trust, address _owner, bytes32[] memory _inheritorHash)
        external
        returns (bool _ok);
}
