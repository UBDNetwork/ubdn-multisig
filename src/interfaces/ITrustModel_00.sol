// SPDX-License-Identifier: MIT
// UBD Network

pragma solidity 0.8.26;

/**
 * @dev Interface of the ITrustModel_00. Use for  tests and externel calls
 */
interface ITrustModel_00 {

    struct DeTrustModelStorage_00 {
        bytes32 inheritorHash;
        uint256 lastOwnerOp;
        address creator;
        uint64 silenceTime;
        bool inherited;
        string name;
    }
    
    function transferNative(address _to, uint256 _value) external;

    // TODO reentrancy checks
    function transferERC20(address _token, address _to, uint256 _amount) external;

    function iAmAlive() external;

    function creator() external view returns(address);

    function trustInfo() external view returns(DeTrustModelStorage_00 memory trust);

   
}
