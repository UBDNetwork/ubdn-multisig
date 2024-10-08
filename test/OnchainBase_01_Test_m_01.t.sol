// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {DeTrustMultisigFactory} from "../src/DeTrustMultisigFactory.sol";
// import {MockMultisigOnchainBase_01} from "../src/mock/MockMultisigOnchainBase_01.sol";
import "../src/mock/MockMultisigOnchainBase_01.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";


// Address:     0x7EC0BF0a4D535Ea220c6bD961e352B752906D568
// Private key: 0x1bbde125e133d7b485f332b8125b891ea2fbb6a957e758db72e6539d46e2cd71

// Address:     0x4b664eD07D19d0b192A037Cfb331644cA536029d
// Private key: 0x3480b19b170c5e63c0bdb18d08c4a99628194c7dceaf79e0e17431f4a5c7b1f2

// Address:     0xd7DE4B1214bFfd5C3E9Fb8A501D1a7bF18569882
// Private key: 0x8ba574046f1e9e372e805aa6c5dcf5598830df5a78605b7713bf00f2f3329148

// Address:     0x6F9aaAaD96180b3D6c71Fbbae2C1c5d5193A64EC
// Private key: 0xae8fe3985898986377b19cc6bdbb76723470552e95e4d028d2dae2691ab9c65d

contract OnchainBase_01_Test is Test {
    address public constant addr1 = 0x7EC0BF0a4D535Ea220c6bD961e352B752906D568;
    address public constant addr2 = 0x4b664eD07D19d0b192A037Cfb331644cA536029d;
    address public constant addr3 = 0xd7DE4B1214bFfd5C3E9Fb8A501D1a7bF18569882;
    address public constant addr4 = 0x6F9aaAaD96180b3D6c71Fbbae2C1c5d5193A64EC;
    uint256 public sendEtherAmount = 1e18;
    uint256 public sendERC20Amount = 2e18;
    string public detrustName = 'NameOfDeTrust';
    address payable public  proxy;
    DeTrustMultisigFactory  public factory;
    MockMultisigOnchainBase_01 public impl_00;
    //eTrustModel_00 public payable impl_00_instance;
    bytes32 _digest_transfer = 0xa42d2b80860bfa2bba37a9d48246f4f2a9f02fbdeeb9b291788dbfe16da6912e;



    MockERC20 public erc20;

    receive() external payable virtual {}
    function setUp() public {
        factory = new DeTrustMultisigFactory(address(0), address(0));
        impl_00 = new MockMultisigOnchainBase_01();
        erc20 = new MockERC20('Mock ERC20 Token', 'MOCK');
        // address _implAddress, 
        // uint8 _threshold,
        // address[] memory _inheritors,
        // uint64[] memory _periodOrDateArray,
        // string memory _name,
        // bytes32  _promoHash
        address[] memory _inheritors = new address[](3);
        _inheritors[0] = addr1;
        _inheritors[1] = addr2;
        _inheritors[2] = addr3;
        uint64[] memory _periodOrDateArray = new uint64[](3);
        _periodOrDateArray[0] = uint64(0);
        _periodOrDateArray[1] = uint64(0);
        _periodOrDateArray[2] = uint64(0);
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00),
            2, 
            _inheritors,
            _periodOrDateArray,
            detrustName, 
            keccak256("PROMO")
        ));
        erc20.transfer(proxy, sendERC20Amount);
    }


    function test_proxyAddress() public view {
        assertEq(address(factory.modelRegistry()), address(0));
        assertEq(address(factory.trustRegistry()), address(0));
        console2.log("Implementation   addr: %s", address(impl_00));
        console2.log("Proxy for     impl_00: %s", proxy);
        assertFalse(address(impl_00) == proxy);
        assertEq(erc20.balanceOf(proxy), sendERC20Amount);
    }

    function test_createOp() public {
        bytes memory _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            addr1, sendERC20Amount/2
        );
       
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);
        // Create op
        vm.startPrank(addr1);
        uint256 lastNonce =  multisig_instance.createAndSign(address(erc20), 0, _data);
        vm.stopPrank();
        MockMultisigOnchainBase_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.ops.length, lastNonce + 1);
        assertEq(info.ops[0].metaTx, _data);

        // Second signature
        vm.startPrank(addr2);
        uint256 signCount = multisig_instance.signAndExecute(lastNonce, false);
        vm.stopPrank(); 
        assertEq(signCount, info.threshold);

        // Execute
        multisig_instance.executeOp(lastNonce);    
        assertEq(erc20.balanceOf(addr1), sendERC20Amount/2);
        assertEq(multisig_instance.getMultisigLastNonce(), 0);
    }

    function test_addSigner_FailAndOK() public {
        bytes memory _data = abi.encodeWithSignature(
            "addSigner(address,uint64)",
            addr4, block.timestamp
        );
       
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);
        vm.expectRevert("Only Self Signed");
        multisig_instance.addSigner(addr4, uint64(block.timestamp));

        vm.startPrank(addr1);
        uint256 lastNonce =  multisig_instance.createAndSign(address(multisig_instance), 0, _data);
        vm.stopPrank();

        // Second signature
        vm.startPrank(addr2);
        uint256 signCount = multisig_instance.signAndExecute(lastNonce, false);
        vm.stopPrank(); 
       

        // Execute
        multisig_instance.executeOp(lastNonce); 

        MockMultisigOnchainBase_01.MultisigOnchainBase_01_Storage memory info 
            = multisig_instance.getMultisigOnchainBase_01();   
        assertEq(4, info.cosigners.length);
        assertEq(signCount, info.threshold);

         // Third signature
        vm.startPrank(addr3);
        vm.expectRevert(
            abi.encodeWithSelector(
                MultisigOnchainBase_01.ActionDeniedForThisStatus.selector, 
                MultisigOnchainBase_01.TxStatus.Executed
            )
        );
        signCount = multisig_instance.signAndExecute(lastNonce, false);
        vm.stopPrank(); 
    }

    function test_createOpSendETH() public {
        bytes memory _data = ""; 
       
        (bool sent, bytes memory data) = proxy.call{value: sendEtherAmount*2}("");
        // suppress solc warnings
        sent;
        data;
        assertEq(proxy.balance, sendEtherAmount*2);
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);
        // Create op
        vm.startPrank(addr1);
        uint256 lastNonce =  multisig_instance.createAndSign(addr4,sendEtherAmount, _data);
        vm.stopPrank();

        MockMultisigOnchainBase_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.ops.length, lastNonce + 1);
        assertEq(info.ops[0].metaTx, _data);
        // if (keccak256(info.ops[0].metaTx) == keccak256(bytes(""))) {
        //     console2.log("Just send ethere");
        //     console2.log(string(bytes(keccak256(bytes("")))));
        // }

        // Second signature
        vm.startPrank(addr2);
        uint256 signCount = multisig_instance.signAndExecute(lastNonce, false);
        vm.stopPrank(); 
        assertEq(signCount, info.threshold);

        // Execute
        multisig_instance.executeOp(lastNonce);    
        assertEq(addr4.balance, sendEtherAmount);
    }
}
