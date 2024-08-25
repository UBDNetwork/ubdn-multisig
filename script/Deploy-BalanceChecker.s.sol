// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../lib/forge-std/src/StdJson.sol";

import {BalanceChecker} from "../src/BalanceChecker.sol";


contract DeployScriptBalanceChecker is Script {
    using stdJson for string;

    function run() public {
        console2.log("Chain id: %s", vm.toString(block.chainid));
        console2.log("Deployer address: %s, native balnce %s", msg.sender, msg.sender.balance);

        // Load json with chain params
        string memory root = vm.projectRoot();
        string memory params_path = string.concat(root, "/script/chain_params.json");
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

        address ubdn_locker;   
        key = string.concat(".", vm.toString(block.chainid),".ubdn_locker");
        if (vm.keyExists(params_json_file, key)) 
        {
            ubdn_locker = params_json_file.readAddress(key);
        } else {
            ubdn_locker = address(0);
        }
        console2.log("ubdn_address: %s", ubdn_locker); 

        
        //////////   Deploy   //////////////
        vm.startBroadcast();
        BalanceChecker checker = new BalanceChecker(ubdn_address, ubdn_locker);
        vm.stopBroadcast();
        
        ///////// Pretty printing ////////////////
        
        string memory path = string.concat(root, "/script/explorers.json");
        string memory json = vm.readFile(path);
        console2.log("Chain id: %s", vm.toString(block.chainid));
        string memory explorer_url = json.readString(
            string.concat(".", vm.toString(block.chainid))
        );
        
        console2.log("\n**BalanceChecker**  ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(checker));

        console2.log("```python");
        console2.log("checker = BalanceChecker.at('%s')", address(checker));
        console2.log("```");
   
        // ///////// End of pretty printing ////////////////

        

    }
}
