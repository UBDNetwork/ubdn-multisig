// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {DeTrustMultisigFactory} from "../src/DeTrustMultisigFactory.sol";
import {MockMultisigOnchainBase_01} from "../src/mock/MockMultisigOnchainBase_01.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";


contract OnchainBase_01_a_Test_02 is Test {
    address public constant cosigner1 = address(11);
    address public constant cosigner2 = address(12);
    address public constant cosigner3 = address(13);
    address public constant cosigner4 = address(14);
    uint256 public sendEtherAmount = 1e18;
    uint256 public sendERC20Amount = 2e18;
    string public detrustName = 'NameOfDeTrust';
    address payable public  proxy;
    DeTrustMultisigFactory  public factory;
    //DeTrustMultisigFactory  public factory;
    MockMultisigOnchainBase_01 public impl_00;
    //eTrustModel_00 public payable impl_00_instance;
    bytes32 _digest_transfer = 0xa42d2b80860bfa2bba37a9d48246f4f2a9f02fbdeeb9b291788dbfe16da6912e;

    receive() external payable virtual {}
    function setUp() public {
        //factory = new DeTrustMultisigFactory(address(0), address(0));
        impl_00 = new MockMultisigOnchainBase_01();
        factory = new DeTrustMultisigFactory(address(0), address(0));
    }

    function test_notEqualArrays() public {
        address[] memory _cosigners = new address[](4);
        _cosigners[0] = cosigner1;
        _cosigners[1] = cosigner2;
        _cosigners[2] = cosigner3;
        _cosigners[3] = cosigner4;
        uint64[] memory _periodOrDateArray = new uint64[](0);
        
        vm.expectRevert('Arrays must be equal');
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00),
            10, 
            _cosigners,
            _periodOrDateArray,
            detrustName, 
            keccak256("PROMO")
        ));
    }

    function test_emptySignersArray() public {
        address[] memory _cosigners = new address[](0);
        uint64[] memory _periodOrDateArray = new uint64[](0);
        
        vm.expectRevert('Not greater then signers count');
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00),
            10, 
            _cosigners,
            _periodOrDateArray,
            detrustName, 
            keccak256("PROMO")
        ));
    }

    function test_thresholdIsZero() public {
        address[] memory _cosigners = new address[](2);
        _cosigners[0] = cosigner1;
        _cosigners[1] =cosigner2;
        uint64[] memory _periodOrDateArray = new uint64[](2);
        _periodOrDateArray[0] = uint64(0);
        _periodOrDateArray[1] = uint64(0);
        
        vm.expectRevert('No zero threshold');
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00),
            0, 
            _cosigners,
            _periodOrDateArray,
            detrustName, 
            keccak256("PROMO")
        ));
    }

    function test_minTwoSigners() public {
        address[] memory _cosigners = new address[](1);
        _cosigners[0] = cosigner1;
        uint64[] memory _periodOrDateArray = new uint64[](1);
        _periodOrDateArray[0] = uint64(0);
        
        vm.expectRevert('At least two signers');
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00),
            0, 
            _cosigners,
            _periodOrDateArray,
            detrustName, 
            keccak256("PROMO")
        ));
    }
}
