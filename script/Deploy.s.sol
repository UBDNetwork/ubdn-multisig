// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../lib/forge-std/src/StdJson.sol";
import {DeTrustFactory}  from "../src/DeTrustFactory.sol";
import {DeTrustModel_00} from "../src/DeTrustModel_00.sol";
import {DeTrustModel_01_Executive} from "../src/DeTrustModel_01_Executive.sol";
import {DeTrustModelRegistry} from "../src/DeTrustModelRegistry.sol";
import {UsersDeTrustRegistry} from "../src/UsersDeTrustRegistry.sol";


contract DeployScript is Script {
    using stdJson for string;

    function run() public {
        console2.log("Chain id: %s", vm.toString(block.chainid));
        console2.log("Deployer address: %s, native balnce %s", msg.sender, msg.sender.balance);

        // Load json with chain params
        //string memory root = vm.projectRoot();
        string memory params_path = string.concat(vm.projectRoot(), "/script/chain_params.json");
        string memory params_json_file = vm.readFile(params_path);
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
        DeTrustModelRegistry modelReg = new DeTrustModelRegistry(fee_benefeciary);
        UsersDeTrustRegistry userReg = new UsersDeTrustRegistry();
        DeTrustFactory factory = new DeTrustFactory(address(modelReg), address(userReg));
        DeTrustModel_00 impl_00 = new DeTrustModel_00();
        DeTrustModel_01_Executive impl_01 = new DeTrustModel_01_Executive();
        vm.stopBroadcast();
        
        ///////// Pretty printing ////////////////
        
        //string memory path = string.concat(vm.projectRoot(), "/script/explorers.json");
        //string memory json = vm.readFile(path);
        params_path = string.concat(vm.projectRoot(), "/script/explorers.json");
        params_json_file = vm.readFile(params_path);
        
        console2.log("Chain id: %s", vm.toString(block.chainid));
        string memory explorer_url = params_json_file.readString(
            string.concat(".", vm.toString(block.chainid))
        );
        
        console2.log("\n**DeTrustModelRegistry**  ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(modelReg));
        console2.log("\n**UsersDeTrustRegistry** ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(userReg));
        console2.log("\n**DeTrustFactory** ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(factory));
        console2.log("\n**DeTrustModel_00** ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(impl_00));
        console2.log("\n**DeTrustModel_01_Executive** ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(impl_01));

        console2.log("```python");
        console2.log("modelReg = DeTrustModelRegistry.at('%s')", address(modelReg));
        console2.log("userReg = UsersDeTrustRegistry.at('%s')", address(userReg));
        console2.log("factory = DeTrustFactory.at('%s')", address(factory));
        console2.log("impl_00 = DeTrustModel_00.at('%s')", address(impl_00));
        console2.log("impl_01 = DeTrustModel_01_Executive.at('%s')", address(impl_01));
        console2.log("```");
   
        // ///////// End of pretty printing ////////////////
        
        // ///  Init ///
        console2.log("Init transactions....");
        vm.startBroadcast();
        modelReg.setModelState(
            address(impl_00),
            DeTrustModelRegistry.TrustModel(0x03, ubdn_address, neededERC20Amount, address(0), 0)
        );
        modelReg.setModelState(
            address(impl_01),
             DeTrustModelRegistry.TrustModel(bytes1(0x07), ubdn_address, neededERC20Amount, ubdn_address, 22e18)
        );
        userReg.setFactoryState(address(factory), true);

        // test transactions
        if (inheriter != address(0)){
            address proxy = factory.deployProxyForTrust(
                address(impl_00), 
                msg.sender,
                keccak256(abi.encode(address(2))), 
                uint64(silentPeriod),
                'InitialTrust'
            );
            console2.log("detrust_00 deployed at('%s')", address(proxy));
            console2.log("https://%s/address/%s#code\n", explorer_url, address(proxy));

            /////////////////
            // DeTrusts 01 //
            /////////////////
            {  //against stack too deep
            bytes32[] memory inheritorHases = new bytes32[](2);
            inheritorHases[0] = keccak256(abi.encode(address(0)));
            inheritorHases[1] = keccak256(abi.encode(inheriter));
            (bytes1 r,,,,uint256 f) = modelReg.approvedModels(address(impl_01));
            IERC20(ubdn_address).approve(address(modelReg), 22e18);
            proxy = factory.deployProxyForTrust(
                address(impl_01), 
                msg.sender,
                inheritorHases, 
                100,
                'Universal DeTrust'
            );
            }
            console2.log("detrust_01 deployed at('%s')", address(proxy));
            console2.log("https://%s/address/%s#code\n", explorer_url, address(proxy));
            ////////////////////
            //   tx_example   //
            ////////////////////
            IERC20(ubdn_address).transfer(proxy, 22_000e18);
            bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", inheriter, 17e18);
            //vm.prank(msg.sender);
            Address.functionCall(proxy, abi.encodeWithSignature(
                "executeOp(address,uint256,bytes)",
                address(ubdn_address), 0, payload
            )); 

            }
            
            vm.stopBroadcast();
            console2.log("Initialisation finished");
    }
}
