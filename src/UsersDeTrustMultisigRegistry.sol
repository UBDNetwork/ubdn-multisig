// SPDX-License-Identifier: MIT
// Users DeTrust Registry for UBD Network

pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUsersDeTrustRegistry.sol";

/**
 * @dev This is deTrust registry for created deTrusts Multisigs.
 */
contract UsersDeTrustMultisigRegistry is IUsersDeTrustRegistry, Ownable {
 
    struct TrustInfo {
        string name;
    }
    mapping(address => address[]) public trustOfCreators;
    mapping(address => address[]) public trustOfInheritors;
    mapping(address => bool) public isDeTrustFactory;
    mapping(address => TrustInfo) public trustInfo;
    

    constructor()
      Ownable(msg.sender)
    {
    }

    /**
     * @dev Register new trust. Must be called only from authorized factory contracts
     * @param _trust  addreess  of creating trust
     * @param _inheritors addersses array. Creator must pass as first(0) element 
     */
    function registerTrust(
        address _trust, 
        address[] memory _inheritors,
        string memory _name
    )
        external
        returns (bool _ok)
    {
        require(isDeTrustFactory[msg.sender], "NonAuthorized factory");
        trustOfCreators[_inheritors[0]].push(_trust);

        for (uint256 i = 0; i < _inheritors.length; ++ i) {
             trustOfInheritors[_inheritors[i]].push(_trust);
        }

        trustInfo[_trust] = TrustInfo(_name);
        
        _ok = true;
    }
    /////////////////////////
    ///  Admin functions  ///
    /////////////////////////

    /**
     * @dev Enable/disable factory contracts
     * @param _factory  addreess  of factory
     * @param _enabled subj
     */
    function setFactoryState(address _factory, bool _enabled) external onlyOwner {
        isDeTrustFactory[_factory] = _enabled;
    }
    
    //////////////////////////////////////////////////////
    /**
     * @dev Returns deTrusts addresses array off given creator  
     * @param _creator address of DeTrus owner.  
     */
    function getCreatorTrusts(address _creator) external view 
        returns(address[] memory trusts) 
    {
        trusts = trustOfCreators[_creator];
    }

    /**
     * @dev Returns deTrusts addresses array off given inheritor  
     * @param _inheritor address of inheritor.  
     */
    function getInheritorTrusts(address _inheritor) external view 
        returns(address[] memory trusts) 
    {
        //bytes32 _inheritorHash =  keccak256(abi.encode(_inheritor));
        trusts = trustOfInheritors[_inheritor];
    }
} 