// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../lib/forge-std/src/StdJson.sol";
import {DeTrustMultisigFactory}  from "../src/DeTrustMultisigFactory.sol";
import {DeTrustMultisigOnchainModel_00} from "../src/DeTrustMultisigOnchainModel_00.sol";
import {DeTrustMultisigOnchainModel_01} from "../src/DeTrustMultisigOnchainModel_01.sol";
import {DeTrustMultisigModelRegistry} from "../src/DeTrustMultisigModelRegistry.sol";
import {UsersDeTrustMultisigRegistry} from "../src/UsersDeTrustMultisigRegistry.sol";

// Address:     0x7EC0BF0a4D535Ea220c6bD961e352B752906D568
// Private key: 0x1bbde125e133d7b485f332b8125b891ea2fbb6a957e758db72e6539d46e2cd71

// Address:     0x4b664eD07D19d0b192A037Cfb331644cA536029d
// Private key: 0x3480b19b170c5e63c0bdb18d08c4a99628194c7dceaf79e0e17431f4a5c7b1f2

// Address:     0xd7DE4B1214bFfd5C3E9Fb8A501D1a7bF18569882
// Private key: 0x8ba574046f1e9e372e805aa6c5dcf5598830df5a78605b7713bf00f2f3329148

// Address:     0x6F9aaAaD96180b3D6c71Fbbae2C1c5d5193A64EC
// Private key: 0xae8fe3985898986377b19cc6bdbb76723470552e95e4d028d2dae2691ab9c65d


contract DeployScript is Script {
    using stdJson for string;

    //address public constant addr1 = 0x7EC0BF0a4D535Ea220c6bD961e352B752906D568;
    address public constant addr2 = 0x4b664eD07D19d0b192A037Cfb331644cA536029d;
    address public constant addr3 = 0xd7DE4B1214bFfd5C3E9Fb8A501D1a7bF18569882;
    address public constant addr4 = 0x6F9aaAaD96180b3D6c71Fbbae2C1c5d5193A64EC;

    function run() public {
        console2.log("Chain id: %s", vm.toString(block.chainid));
        console2.log("Deployer address: %s, native balnce %s", msg.sender, msg.sender.balance);

        // Load json with chain params
        //string memory root = vm.projectRoot();
        //string memory params_path = string.concat(vm.projectRoot(), "/script/chain_params.json");
        string memory params_json_file = vm.readFile(string.concat(vm.projectRoot(), "/script/chain_params.json"));
        string memory key;

        // Define constructor params
        address ubdn_address;   
        key = string.concat(".", vm.toString(block.chainid),".ubdn_address");
        if (vm.keyExists(params_json_file, key)) 
        {
            ubdn_address = params_json_file.readAddress(key);
        } else {
            ubdn_address = address(0);
        }
        console2.log("ubdn_address: %s", ubdn_address); 

        uint256 neededERC20Amount;
        key = string.concat(".", vm.toString(block.chainid),".neededERC20Amount");
        if (vm.keyExists(params_json_file, key)) 
        {
            neededERC20Amount = params_json_file.readUint(key);
        } else {
            neededERC20Amount = 0;
        }
        console2.log("neededERC20Amount: %s", neededERC20Amount); 
        
        address inheriter;
        key = string.concat(".", vm.toString(block.chainid),".inheriter");
        if (vm.keyExists(params_json_file, key)) 
        {
            inheriter = params_json_file.readAddress(key);
        } else {
            inheriter = address(0);
        }
        console2.log("inheriter: %s", inheriter); 
        
        uint256 silentPeriod;
        key = string.concat(".", vm.toString(block.chainid),".silentPeriod");
        if (vm.keyExists(params_json_file, key)) 
        {
            silentPeriod = params_json_file.readUint(key);
        } else {
            silentPeriod = 0;
        }
        console2.log("silentPeriod: %s", silentPeriod); 

        address fee_benefeciary;
        key = string.concat(".", vm.toString(block.chainid),".fee_benefeciary");
        if (vm.keyExists(params_json_file, key)) 
        {
            fee_benefeciary = params_json_file.readAddress(key);
        } else {
            fee_benefeciary = msg.sender;
        }
        console2.log("fee_benefeciary: %s", fee_benefeciary); 
        

        //////////   Deploy   //////////////
        vm.startBroadcast();
        DeTrustMultisigModelRegistry modelReg = new DeTrustMultisigModelRegistry(fee_benefeciary);
        UsersDeTrustMultisigRegistry userReg = new UsersDeTrustMultisigRegistry();
        DeTrustMultisigFactory factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));
        DeTrustMultisigOnchainModel_00 impl_00 = new DeTrustMultisigOnchainModel_00();
        DeTrustMultisigOnchainModel_01 impl_01 = new DeTrustMultisigOnchainModel_01();
        vm.stopBroadcast();
        
        ///////// Pretty printing ////////////////
        
        //string memory path = string.concat(vm.projectRoot(), "/script/explorers.json");
        //string memory json = vm.readFile(path);
        //params_path = string.concat(vm.projectRoot(), "/script/explorers.json");
        params_json_file = vm.readFile(string.concat(vm.projectRoot(), "/script/explorers.json"));
        
        console2.log("Chain id: %s", vm.toString(block.chainid));
        string memory explorer_url = params_json_file.readString(
            string.concat(".", vm.toString(block.chainid))
        );
        
        console2.log("\n**DeTrustMultisigModelRegistry**  ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(modelReg));
        console2.log("\n**UsersDeTrustMultisigRegistry** ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(userReg));
        console2.log("\n**DeTrustMultisigFactory** ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(factory));
        console2.log("\n**DeTrustMultisigOnchainModel_00** ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(impl_00));
        console2.log("\n**DeTrustMultisigOnchainModel_01** ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(impl_01));

        console2.log("```python");
        console2.log("modelReg = DeTrustMultisigModelRegistry.at('%s')", address(modelReg));
        console2.log("userReg = UsersDeTrustMultisigRegistrygjx.at('%s')", address(userReg));
        console2.log("factory = DeTrustMultisigFactory.at('%s')", address(factory));
        console2.log("impl_00 = DeTrustMultisigOnchainModel_00.at('%s')", address(impl_00));
        console2.log("impl_01 = DeTrustMultisigOnchainModel_01.at('%s')", address(impl_01));
        console2.log("```");
   
        // ///////// End of pretty printing ////////////////
        
        // ///  Init ///
        console2.log("Init transactions....");
        vm.startBroadcast();
        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(0x03, ubdn_address, neededERC20Amount, address(0), 0)
        );
        modelReg.setModelState(
            address(impl_01),
             DeTrustMultisigModelRegistry.TrustModel(bytes1(0x07), ubdn_address, neededERC20Amount, ubdn_address, 22e18)
        );
        userReg.setFactoryState(address(factory), true);

        // test transactions
        if (inheriter != address(0)){
            address proxy;
            {
                address[] memory _inheritors = new address[](3);
                _inheritors[0] = 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3;
                _inheritors[1] = addr2;
                _inheritors[2] = addr3;
                uint64[] memory _periodOrDateArray = new uint64[](3);
                _periodOrDateArray[0] = uint64(0);
                _periodOrDateArray[1] = uint64(2);
                _periodOrDateArray[2] = uint64(3);
                proxy = factory.deployProxyForTrust(
                    address(impl_00), 2,
                    _inheritors,
                    _periodOrDateArray, 
                    'Universal DeTrust',
                    keccak256("PROMO")
                );
            }
                console2.log("detrust_00 deployed at('%s')", address(proxy));
                console2.log("https://%s/address/%s#code\n", explorer_url, address(proxy));
          
            ////////////////////
            //   tx_example   //
            ////////////////////
            IERC20(ubdn_address).transfer(proxy, 22_000e18);

            DeTrustMultisigOnchainModel_00 multisig_instance = DeTrustMultisigOnchainModel_00(proxy);
            bytes memory _data = abi.encodeWithSignature(
                "transfer(address,uint256)",
                0x4b664eD07D19d0b192A037Cfb331644cA536029d, 7000e18
            );
            multisig_instance.createAndSign(address(ubdn_address), 0, _data);

        }
            
            vm.stopBroadcast();
            console2.log("Initialisation finished");
    }
}
