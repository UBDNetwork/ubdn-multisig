// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../lib/forge-std/src/StdJson.sol";
import {DeTrustMultisigFactory}  from "../src/DeTrustMultisigFactory.sol";
import {DeTrustMultisigOnchainModel_00} from "../src/DeTrustMultisigOnchainModel_00.sol";
import {DeTrustMultisigOnchainModel_01} from "../src/DeTrustMultisigOnchainModel_01.sol";
import {DeTrustMultisigOnchainModel_Free} from "../src/DeTrustMultisigOnchainModel_Free.sol";
import {DeTrustMultisigModelRegistry} from "../src/DeTrustMultisigModelRegistry.sol";
import {UsersDeTrustMultisigRegistry} from "../src/UsersDeTrustMultisigRegistry.sol";
import {MockPromoManager} from "../src/mock/MockPromoManager.sol";

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

    struct Params {
        address ubdn_address;   
        uint256 neededERC20Amount;
        address inheriter;
        uint256 silentPeriod;
        address fee_benefeciary;
        address ubdn_balance_checker;
    }



    //address public constant addr1 = 0x7EC0BF0a4D535Ea220c6bD961e352B752906D568;
    address public constant addr2 = 0x4b664eD07D19d0b192A037Cfb331644cA536029d;
    address public constant addr3 = 0xd7DE4B1214bFfd5C3E9Fb8A501D1a7bF18569882;
    address public constant addr4 = 0x6F9aaAaD96180b3D6c71Fbbae2C1c5d5193A64EC;

    Params p; 

    function run() public {
        console2.log("Chain id: %s", vm.toString(block.chainid));
        console2.log(
            "Deployer address: %s, "
            "\n native balnce %s",
            msg.sender, msg.sender.balance);
         
        // Load json with chain params
        //string memory root = vm.projectRoot();
        //string memory params_path = string.concat(vm.projectRoot(), "/script/chain_params.json");
        string memory params_json_file = vm.readFile(string.concat(vm.projectRoot(), "/script/chain_params.json"));
        string memory key;
        
        // Define constructor params
        //address ubdn_address;   
        key = string.concat(".", vm.toString(block.chainid),".ubdn_address");
        if (vm.keyExists(params_json_file, key)) 
        {
            p.ubdn_address = params_json_file.readAddress(key);
        } else {
            p.ubdn_address = address(0);
        }
        if  (p.ubdn_address != address(0)){
            console2.log("ubdn_address: %s, \n ubdn balnce %s",
                p.ubdn_address, 
                IERC20(p.ubdn_address).balanceOf(msg.sender)/1e18
            ); 
        }
        

        //uint256 neededERC20Amount;
        key = string.concat(".", vm.toString(block.chainid),".neededERC20Amount");
        if (vm.keyExists(params_json_file, key)) 
        {
            p.neededERC20Amount = params_json_file.readUint(key);
        } else {
            p.neededERC20Amount = 0;
        }
        console2.log("neededERC20Amount: %s", p.neededERC20Amount); 
        
        //address inheriter;
        key = string.concat(".", vm.toString(block.chainid),".inheriter");
        if (vm.keyExists(params_json_file, key)) 
        {
            p.inheriter = params_json_file.readAddress(key);
        } else {
            p.inheriter = address(0);
        }
        console2.log("inheriter: %s", p.inheriter); 
        
        //uint256 silentPeriod;
        key = string.concat(".", vm.toString(block.chainid),".silentPeriod");
        if (vm.keyExists(params_json_file, key)) 
        {
            p.silentPeriod = params_json_file.readUint(key);
        } else {
            p.silentPeriod = 0;
        }
        console2.log("silentPeriod: %s", p.silentPeriod); 

        //address fee_benefeciary;
        key = string.concat(".", vm.toString(block.chainid),".fee_benefeciary");
        if (vm.keyExists(params_json_file, key)) 
        {
            p.fee_benefeciary = params_json_file.readAddress(key);
        } else {
            p.fee_benefeciary = msg.sender;
        }
        console2.log("fee_benefeciary: %s", p.fee_benefeciary); 

        //address ubdn_balance_checker;
        key = string.concat(".", vm.toString(block.chainid),".ubdn_balance_checker");
        if (vm.keyExists(params_json_file, key)) 
        {
            p.ubdn_balance_checker = params_json_file.readAddress(key);
        } else {
            p.ubdn_balance_checker = address(0);
        }
        console2.log("ubdn_balance_checker: %s", p.ubdn_balance_checker); 
        

        //////////   Deploy   //////////////
        vm.startBroadcast();
        DeTrustMultisigModelRegistry modelReg = new DeTrustMultisigModelRegistry(p.fee_benefeciary);
        UsersDeTrustMultisigRegistry userReg = new UsersDeTrustMultisigRegistry();
        DeTrustMultisigFactory factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));
        DeTrustMultisigOnchainModel_00 impl_00 = new DeTrustMultisigOnchainModel_00();
        DeTrustMultisigOnchainModel_01 impl_01 = new DeTrustMultisigOnchainModel_01();
        DeTrustMultisigOnchainModel_Free impl_free = new DeTrustMultisigOnchainModel_Free();
        MockPromoManager promoM = new MockPromoManager();
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
        console2.log("\n**DeTrustMultisigOnchainModel_Free** ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(impl_free));



        console2.log("```python");
        console2.log("modelReg = DeTrustMultisigModelRegistry.at('%s')", address(modelReg));
        console2.log("userReg = UsersDeTrustMultisigRegistrygjx.at('%s')", address(userReg));
        console2.log("factory = DeTrustMultisigFactory.at('%s')", address(factory));
        console2.log("impl_00 = DeTrustMultisigOnchainModel_00.at('%s')", address(impl_00));
        console2.log("impl_01 = DeTrustMultisigOnchainModel_01.at('%s')", address(impl_01));
        console2.log("impl_free = DeTrustMultisigOnchainModel_Free.at('%s')", address(impl_free));
        console2.log("```");
   
        // ///////// End of pretty printing ////////////////
        
        // ///  Init ///
        console2.log("Init transactions....");
        vm.startBroadcast();
        if (p.ubdn_balance_checker != address(0)){
            modelReg.setMinHoldAddress(p.ubdn_balance_checker);    
        } else {
            modelReg.setMinHoldAddress(p.ubdn_address);    
        }
        
        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(
                0x03, 
                p.ubdn_balance_checker, 
                p.neededERC20Amount, 
                address(0), 
                0
            )
        );
        modelReg.setModelState(
            address(impl_01),
             DeTrustMultisigModelRegistry.TrustModel(
                bytes1(0x03), 
                p.ubdn_balance_checker, 
                p.neededERC20Amount, 
                address(0), 
                0
            )
        );
        modelReg.setModelState(
            address(impl_free),
             DeTrustMultisigModelRegistry.TrustModel(
                bytes1(0x01), 
                address(0), 
                0, 
                address(0), 
                0
            )
        );
        userReg.setFactoryState(address(factory), true);
        // init - enable PROMO
        //modelReg.setPromoCodeManager(address(promoM));


        // test transactions
        if (p.inheriter != address(0)){
            IERC20(p.ubdn_address).approve(address(modelReg), 22_000e18);
            address payable proxy;
            address payable proxy01;
            address payable proxy02;
            {
                address[] memory _inheritors = new address[](4);
                _inheritors[0] = 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3;
                _inheritors[1] = 0x6ddb97905c9Eb0A41e6400E1cD31A063214a4068;
                _inheritors[2] = addr3;
                _inheritors[3] = address(this);
                uint64[] memory _periodOrDateArray = new uint64[](4);
                _periodOrDateArray[0] = uint64(0);
                _periodOrDateArray[1] = uint64(2);
                _periodOrDateArray[2] = uint64(3);
                _periodOrDateArray[3] = uint64(4);
                proxy = payable(factory.deployProxyForTrust(
                    address(impl_00), 2,
                    _inheritors,
                    _periodOrDateArray, 
                    'Universal DeTrust',
                    keccak256("PROMO")
                ));
                IERC20(p.ubdn_address).transfer(proxy, 22_000e18);
            }
            console2.log("detrust_00 deployed at('%s')", address(proxy));
            console2.log("https://%s/address/%s#code\n", explorer_url, address(proxy));

            {
                address[] memory _inheritors = new address[](4);
                _inheritors[0] = 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3;
                _inheritors[1] = 0x6ddb97905c9Eb0A41e6400E1cD31A063214a4068;
                _inheritors[2] = addr3;
                _inheritors[3] = address(this);
                uint64[] memory _periodOrDateArray = new uint64[](4);
                _periodOrDateArray[0] = uint64(0);
                _periodOrDateArray[1] = uint64(300);
                _periodOrDateArray[2] = uint64(3);
                _periodOrDateArray[3] = uint64(4);
                proxy01 = payable(factory.deployProxyForTrust(
                    address(impl_01), 2,
                    _inheritors,
                    _periodOrDateArray, 
                    'Silent time DeTrust',
                    keccak256("PROMO")
                ));
                IERC20(p.ubdn_address).transfer(proxy01, 22_000e18);
            }
            console2.log("detrust_01 (Silent) deployed at('%s')", address(proxy01));
            console2.log("https://%s/address/%s#code\n", explorer_url, address(proxy01));
            {
                address[] memory _inheritors = new address[](4);
                _inheritors[0] = 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3;
                _inheritors[1] = 0x6ddb97905c9Eb0A41e6400E1cD31A063214a4068;
                _inheritors[2] = addr3;
                _inheritors[3] = address(this);
                uint64[] memory _periodOrDateArray = new uint64[](4);
                _periodOrDateArray[0] = uint64(0);
                _periodOrDateArray[1] = uint64(2);
                _periodOrDateArray[2] = uint64(3);
                _periodOrDateArray[3] = uint64(4);
                proxy02 = payable(factory.deployProxyForTrust(
                    address(impl_free), 2,
                    _inheritors,
                    _periodOrDateArray, 
                    'Universal DeTrust Free',
                    keccak256("")
                ));
                IERC20(p.ubdn_address).transfer(proxy02, 22_000e18);
            }
            console2.log("detrust_Free deployed at('%s')", address(proxy02));
            console2.log("https://%s/address/%s#code\n", explorer_url, address(proxy02));
          
            /////////////////////////
            //   tx_example  erc20 //
            /////////////////////////
            {
                DeTrustMultisigOnchainModel_00 multisig_instance = DeTrustMultisigOnchainModel_00(proxy);
                bytes memory _data = abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    0x4b664eD07D19d0b192A037Cfb331644cA536029d, 7000e18
                );
                console2.log("createAndSign....erc20");
                multisig_instance.createAndSign(address(p.ubdn_address), 0, _data);

                // tx send ether
                _data = "";
                console2.log("createAndSign....send ether");
                multisig_instance.createAndSign(addr3, 1, _data);
            }

            {
                DeTrustMultisigOnchainModel_01 multisig_instance = DeTrustMultisigOnchainModel_01(proxy01);
                bytes memory _data = abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    0x4b664eD07D19d0b192A037Cfb331644cA536029d, 7000e18
                );
                console2.log("createAndSign....erc20");
                multisig_instance.createAndSign(address(p.ubdn_address), 0, _data);

                // tx send ether
                _data = "";
                console2.log("createAndSign....send ether");
                multisig_instance.createAndSign(addr3, 1, _data);
                multisig_instance.iAmAlive();

            }

            {
                DeTrustMultisigOnchainModel_Free multisig_instance = DeTrustMultisigOnchainModel_Free(proxy02);
                bytes memory _data = abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    0x4b664eD07D19d0b192A037Cfb331644cA536029d, 7000e18
                );
                console2.log("createAndSign....erc20");
                multisig_instance.createAndSign(address(p.ubdn_address), 0, _data);

                // tx send ether
                _data = "";
                console2.log("createAndSign....send ether");
                multisig_instance.createAndSign(addr3, 1, _data);
            }
        }
            vm.stopBroadcast();
            console2.log("Initialisation finished");
    }
}
