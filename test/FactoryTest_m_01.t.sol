// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {DeTrustMultisigFactory} from "../src/DeTrustMultisigFactory.sol";
import {DeTrustMultisigModel_01} from "../src/DeTrustMultisigModel_01.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";
//import {ITrustModel_00} from "../src/interfaces/ITrustModel_00.sol";

// Digest for sign
// 0xa42d2b80860bfa2bba37a9d48246f4f2a9f02fbdeeb9b291788dbfe16da6912e

// Address:     0x7EC0BF0a4D535Ea220c6bD961e352B752906D568
// Private key: 0x1bbde125e133d7b485f332b8125b891ea2fbb6a957e758db72e6539d46e2cd71
// Signature:   0x18a2060e6d51e1a8bce0a7820214d409c785ed4d6d5dc2fbf7b3eb809adc365f206a6b2f56a5793480b567b0856a3c67b5fb25322c0f6b58932af53927de5c921b

// Address:     0x4b664eD07D19d0b192A037Cfb331644cA536029d
// Private key: 0x3480b19b170c5e63c0bdb18d08c4a99628194c7dceaf79e0e17431f4a5c7b1f2
// Signature:   0xa3cfaff3a5e772948034b5a099cfa27d6dfa30325375f9950bc9ed84cc0d601a56c990cdc87f81d68bdfbfb86d02e0f54446a773ff334f3b670c009b18f8dd9d1b

// Address:     0xd7DE4B1214bFfd5C3E9Fb8A501D1a7bF18569882
// Private key: 0x8ba574046f1e9e372e805aa6c5dcf5598830df5a78605b7713bf00f2f3329148
// Signature: 0x53a1a493a25b65aa4bca11d2971d61ee04477274372daa5bbb04b6a163fd7fd10f4a9e5921de5a2ae4f4d92d76894e94f97c7b839b0bbc1d4f48d35e0ce2700b1b

contract FactoryTest_m_01 is Test {
    address public constant addr1 = 0x7EC0BF0a4D535Ea220c6bD961e352B752906D568;
    address public constant addr2 = 0x4b664eD07D19d0b192A037Cfb331644cA536029d;
    address public constant addr3 = 0xd7DE4B1214bFfd5C3E9Fb8A501D1a7bF18569882;
    uint256 public sendEtherAmount = 1e18;
    uint256 public sendERC20Amount = 2e18;
    string public detrustName = 'NameOfDeTrust';
    address payable public  proxy;
    DeTrustMultisigFactory  public factory;
    DeTrustMultisigModel_01 public impl_00;
    //eTrustModel_00 public payable impl_00_instance;
    bytes32 _digest_transfer = 0xa42d2b80860bfa2bba37a9d48246f4f2a9f02fbdeeb9b291788dbfe16da6912e;



    MockERC20 public erc20;

    receive() external payable virtual {}
    function setUp() public {
        factory = new DeTrustMultisigFactory(address(0), address(0));
        impl_00 = new DeTrustMultisigModel_01();
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
        _periodOrDateArray[1] = uint64(1);
        _periodOrDateArray[2] = uint64(2);
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

    function test_zeroRegistry() public {
        assertEq(address(factory.modelRegistry()), address(0));
        assertEq(address(factory.trustRegistry()), address(0));
    }

    function test_proxyAddress() public {
        console2.log("Implementation   addr: %s", address(impl_00));
        console2.log("Proxy for     impl_00: %s", proxy);
        assertFalse(address(impl_00) == proxy);
        assertEq(erc20.balanceOf(proxy), sendERC20Amount);
    }


    function test_erc20Transfer() public {

        bytes memory _data = abi.encodeWithSignature(
            "transferERC20(address,address,uint256)",
            address(erc20), address(this), sendERC20Amount/2
        );
        // get digest for sign
        DeTrustMultisigModel_01 multisig_instance = DeTrustMultisigModel_01(proxy);
        bytes[] memory _signatures = new bytes[](3);
        _signatures[0] = hex"18a2060e6d51e1a8bce0a7820214d409c785ed4d6d5dc2fbf7b3eb809adc365f206a6b2f56a5793480b567b0856a3c67b5fb25322c0f6b58932af53927de5c921b";
        _signatures[1] = hex"a3cfaff3a5e772948034b5a099cfa27d6dfa30325375f9950bc9ed84cc0d601a56c990cdc87f81d68bdfbfb86d02e0f54446a773ff334f3b670c009b18f8dd9d1b";
        _signatures[2] = hex"53a1a493a25b65aa4bca11d2971d61ee04477274372daa5bbb04b6a163fd7fd10f4a9e5921de5a2ae4f4d92d76894e94f97c7b839b0bbc1d4f48d35e0ce2700b1b";
        multisig_instance.executeOp(
            address(erc20), 0, _data, _signatures 
        );
        // bytes32 digest_nonce_0 = multisig_instance.txDataDigest(
        //     address(erc20), //  _erc20
        //     0,     //  _value
        //     _data,
        //     0      //  _nonce
        // ); 


        // bytes memory returndata = Address.functionStaticCall(proxy, _data);
        // DeTrustModel_00.DeTrustModelStorage memory s = abi.decode(returndata, (DeTrustModel_00.DeTrustModelStorage));
        
        // console2.log("Trust creator: %s", s.creator);
        // console2.log("Last op: %s", s.lastOwnerOp);
        // console2.log("ST: %s", s.silenceTime);
        // console2.log("inherited: %s", s.inherited);

        // assertEq(erc20.balanceOf(proxy), 0);
        // assertEq(erc20.balanceOf(address(this)), erc20.totalSupply());
        // erc20.transfer(proxy, sendERC20Amount);
        // assertEq(erc20.balanceOf(proxy), sendERC20Amount);
        // vm.prank(msg.sender);
        // bytes memory _returnData = Address.functionCall(proxy, abi.encodeWithSignature(
        //     "transferERC20(address,address,uint256)",
        //     address(erc20), address(this), sendERC20Amount/2
        // ));
        // assertEq(erc20.balanceOf(proxy), sendERC20Amount/2);

    }

    // function test_etherBalance() public {

    //     address proxy = factory.deployProxyForTrust(
    //         address(impl_00), 
    //         msg.sender,
    //         keccak256(abi.encode(address(0))), 
    //         0,
    //         detrustName
    //     );
    //     console2.log("Implementation   addr: %s", address(impl_00));
    //     console2.log("Proxy for     impl_00: %s", proxy);
    //     console2.log("Msg.sender in    test: %s", msg.sender);
    //     console2.log("Test contract address: %s", msg.sender);
    //     console2.log("ETH balnce of Test contract: %s", address(this).balance);
    //     assertEq(proxy.balance, 0);
    //     assertFalse(address(this).balance == 0);
    //     address payable _receiver = payable(proxy);
    //     _receiver.transfer(sendEtherAmount);
    //     assertEq(address(proxy).balance, sendEtherAmount);
    //     bytes memory _returnData = Address.functionStaticCall(proxy, abi.encodeWithSignature(
    //         "creator()"
    //     ));
    //     address _creatorFromCall = address(uint160(uint256(bytes32(_returnData))));
    //     console2.log("Creator from staticcal: %s", _creatorFromCall);
    //     console2.log("ETH balnce of Test contract: %s", address(this).balance);
    //     vm.prank(msg.sender);
    //     _returnData = Address.functionCall(proxy, abi.encodeWithSignature(
    //         "transferNative(address,uint256)",
    //         _creatorFromCall, sendEtherAmount/2
            
    //     ));
    //     assertEq(address(proxy).balance, sendEtherAmount/2);

    // }
}
