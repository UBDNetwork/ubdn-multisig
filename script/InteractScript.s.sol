// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import "../lib/forge-std/src/StdJson.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DeTrustMultisigFactory} from "../src/DeTrustMultisigFactory.sol";
import {UsersDeTrustMultisigRegistry} from "../src/UsersDeTrustMultisigRegistry.sol";
import {DeTrustMultisigModelRegistry} from "../src/DeTrustMultisigModelRegistry.sol";
import {DeTrustMultisigOnchainModel_00} from "../src/DeTrustMultisigOnchainModel_00.sol";
import {DeTrustMultisigOnchainModel_01} from "../src/DeTrustMultisigOnchainModel_01.sol";
import {DeTrustMultisigOnchainModel_Free} from "../src/DeTrustMultisigOnchainModel_Free.sol";


contract InteracteScript is Script {
    using stdJson for string;
    address payable _modelReg = payable(0xB5C0efdEc9a5252A778D91724e8F02e87CB06400);
    address _userReg = 0x815eb5679636B4FdD38cC5282E018730047f9b6c;
    address payable _factory = payable(0x9680b34564c1414738FeD7070fb512D327653837);
    address payable _impl_00 = payable(0xa333299B073D0cF91b1A814A8892201445f28d4c);
    address payable _impl_01 = payable(0xde6E36c7755CBB7B3cD3E6ad9047Be6c7579Be00);
    address payable _impl_free = payable(0x04C006650d3aF0ae0b6fB7A2D53101b811262DDe);
    address _ubdn = 0x7ce7abb7F8794dCe67FB2dc4d8eBf2F033472730;
    address _routerV2 = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;
    address _weth = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    address _usdt = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;

    uint256 feeAmount = 220e18;
    uint256 etherAmount = 1e15;
    uint256 ubdnAmount = 1e18;
    uint256 withdrawERC20Amount = 1e16;
    uint256 withdrawEtherAmount = 1e12;
      
    
    DeTrustMultisigModelRegistry modelReg = DeTrustMultisigModelRegistry(_modelReg);
    UsersDeTrustMultisigRegistry userReg = UsersDeTrustMultisigRegistry(_userReg);
    DeTrustMultisigOnchainModel_00 impl_00 = DeTrustMultisigOnchainModel_00(_impl_00);
    DeTrustMultisigOnchainModel_01 impl_01 = DeTrustMultisigOnchainModel_01(_impl_01);
    DeTrustMultisigFactory factory = DeTrustMultisigFactory(_factory);
    DeTrustMultisigOnchainModel_Free impl_free = DeTrustMultisigOnchainModel_Free(_impl_free);

    
    // console2.log("factory: %s", address(factory));

    address[] inheritors = new address[](2);
    uint64[] periodOrDateArray = new uint64[](2);
    uint256 amount = 10e18;
    uint64 silentPeriod = 10000;
    string detrustName = 'Alex trust';
    uint256 inheritedTime = block.timestamp + 10000;
    uint8 threshold = 2;
    bytes32  promoHash = 0x0;
    address payable proxy;

    function run() public {
        console2.log("Chain id: %s", vm.toString(block.chainid));
        console2.log("Msg.sender address: %s, %s", msg.sender, msg.sender.balance);


        // Load json with chain params
        string memory root = vm.projectRoot();
        string memory params_path = string.concat(root, "/script/chain_params.json");
        string memory params_json_file = vm.readFile(params_path);
        string memory key;
        console2.log('Hi');

        // 

        inheritors[0] = 0x5992Fe461F81C8E0aFFA95b831E50e9b3854BA0E;
        inheritors[1] = 0xf315B9006C20913D6D8498BDf657E778d4Ddf2c4;
        address creator = 0x5992Fe461F81C8E0aFFA95b831E50e9b3854BA0E;
        //address receiver = 0xf315B9006C20913D6D8498BDf657E778d4Ddf2c4;
        periodOrDateArray[0] = 0;
        periodOrDateArray[1] = 0;

        vm.startBroadcast();
        /*proxy = payable(factory.deployProxyForTrust(
            address(impl_free), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,
            promoHash
        ));*/

        proxy = payable(0xAfaF31c55d224b9601653c925227a1b29a46d1a9);

        DeTrustMultisigOnchainModel_Free multisig_instance = DeTrustMultisigOnchainModel_Free(proxy);
        
        // make approve //
        // bytes memory _data = abi.encodeWithSignature("approve(address,uint256)", _routerV2, 1e15);
        //console2.log('allowance = ', IERC20(_weth).allowance(proxy, _routerV2));
        // uint256 lastNonce = multisig_instance.createAndSign(_weth, 0, _data);
        // multisig_instance.signAndExecute(0, false);
        // multisig_instance.executeOp(0);

        // make swap erc20 to erc20 //

        address[] memory _path = new address[](2);
        _path[0] = _weth; // weth
        _path[1] = _usdt; // usdt
        bytes memory _data = abi.encodeWithSignature("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",1e15,0,_path,proxy,2*block.timestamp);


        // multisig_instance.createAndSign(_routerV2, 0, _data); // before add erc20 tokens to proxy and make approve for _routerV2 from proxy
        // multisig_instance.signAndExecute(1, true);

        // make swap eth to usdt - uniswap v2
        // bytes memory _data = abi.encodeWithSignature("swapExactETHForTokens(uint256,address[],address,uint256)",0,_path,proxy,2*block.timestamp);
        // multisig_instance.createAndSign(_routerV2, 1e10, _data); // before add eth to proxy
        // multisig_instance.signAndExecute(5, true);

        vm.stopBroadcast();

    }
}