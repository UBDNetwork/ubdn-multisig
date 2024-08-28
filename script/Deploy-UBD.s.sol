// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../lib/forge-std/src/StdJson.sol";

import {UBDerc20} from "../src/mock/UBDerc20.sol";


contract DeployScriptUBD is Script {
    using stdJson for string;

    function run() public {
        console2.log("Chain id: %s", vm.toString(block.chainid));
        console2.log("Deployer address: %s, native balnce %s", msg.sender, msg.sender.balance);

        // Load json with chain params
        string memory root = vm.projectRoot();
        string memory params_path = string.concat(root, "/script/chain_params.json");
        string memory params_json_file = vm.readFile(params_path);
        string memory key;

               
        //////////   Deploy   //////////////
        vm.startBroadcast();
        UBDerc20 erc20 = new UBDerc20(address(0x4d4b73C12a209Bf6b087413f0500f58E84F2144b));
        vm.stopBroadcast();
        
        ///////// Pretty printing ////////////////
        
        string memory path = string.concat(root, "/script/explorers.json");
        string memory json = vm.readFile(path);
        console2.log("Chain id: %s", vm.toString(block.chainid));
        string memory explorer_url = json.readString(
            string.concat(".", vm.toString(block.chainid))
        );
        
        console2.log("\n**UBDerc20**  ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(erc20));

        console2.log("```python");
        console2.log("checker = UBDerc20.at('%s')", address(erc20));
        console2.log("```");
   
        // ///////// End of pretty printing ////////////////

        

    }
}
