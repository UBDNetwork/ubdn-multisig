// SPDX-License-Identifier: MIT
// UBD Network

pragma solidity 0.8.26;

import "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IDeTrustModelRegistry.sol";
import "./interfaces/IUsersDeTrustRegistry.sol";

/**
 * @dev This is a factory contract for UBD DeTrustMultisig creation. DeTrusts will
 * creating as minimal proxy (EIP 1167) for available model implementation.  
 */
contract DeTrustMultisigFactory {

    struct FeeParams {
        address feeToken;
        uint256 feeAmount;
        address feeBeneficiary;
        uint64 prePaiedPeriod;
    }

    uint8 constant public MAX_NAME_LENGTH_BYTES = 52;
    IDeTrustModelRegistry public modelRegistry;
    IUsersDeTrustRegistry public trustRegistry;
    
    
    event NewTrust(address Creator, address Model, address Trust, string Name);
    
    /**
     * @dev Pass Model's and User's Registry contract addresses.  Zero addresses
     * are possible as well but in that case proxy for **ANY** implementation 
     * would be able to create.
     */
    constructor(address _modelReg, address _trustReg){
        modelRegistry = IDeTrustModelRegistry(_modelReg);
        trustRegistry = IUsersDeTrustRegistry(_trustReg);
    }

    

    /**
     * @dev Deploy proxy for given implementation.
     * @param _implAddress  addreess  of approved and valid implemtation
     * @param _threshold number of sign that enough for execute tx
     * @param _inheritors addresses array. First address is  DeTrust owner.  So in theory possible to
     *   create detrust for somebody. But only `msg.sender` address will checked
     * in model creation rules.
     * @param _periodOrDateArray array periods in seconds after wich inheritor will get acces to.
     * @param _name simple string name for trust. 
     * @param _promoHash - hashed promocode value
     */
    function deployProxyForTrust(
        address _implAddress, 
        uint8 _threshold,
        address[] memory _inheritors,
        uint64[] memory _periodOrDateArray,
        string memory _name,
        bytes32  _promoHash
    ) public payable returns(address proxy) 
    {
        FeeParams memory feep;
        require(bytes(_name).length <= MAX_NAME_LENGTH_BYTES, "Too long name");
        if (address(modelRegistry) != address(0)){
            bytes1 _rules = modelRegistry.isModelEnable(_implAddress, msg.sender);
            // check _implAddress(=model) white list
            require(_rules & 0x01 == 0x01, "Model not approved");
            
            // check model rules
            if (_rules & 0x02 == 0x02) {
                modelRegistry.checkRules(_implAddress, msg.sender, _promoHash);
            }

            // charge FEE if enabled
            if (_rules & 0x04 == 0x04) {
                (feep.feeToken, feep.feeAmount, feep.feeBeneficiary, feep.prePaiedPeriod) 
                    =  modelRegistry.chargeFee{value: msg.value}(
                        _implAddress, msg.sender, _promoHash
                    );
            }
        }

        proxy = Clones.clone(_implAddress);

        // INIT
        bytes memory initCallData = abi.encodeWithSignature(
            "initialize(uint8,address[],uint64[],address,uint256,address,uint64)",
            _threshold, _inheritors, _periodOrDateArray
            ,feep.feeToken, feep.feeAmount, feep.feeBeneficiary, feep.prePaiedPeriod
        );
        // Address.functionCallWithValue(proxy, initCallData, msg.value);
        Address.functionCallWithValue(proxy, initCallData, 0);


        // Register trust in Trust registry
        if (address(trustRegistry) != address(0)){
            trustRegistry.registerTrust(proxy, _inheritors, _name);
        }
        emit NewTrust(msg.sender, _implAddress, proxy, _name);
    }

    function getMinHoldInfo() external view returns (uint256, address) {
        if (address(modelRegistry) != address(0)){
            return modelRegistry.getMinHoldInfo();
        } else {
            return (0, address(0));
        }
    }

    
}