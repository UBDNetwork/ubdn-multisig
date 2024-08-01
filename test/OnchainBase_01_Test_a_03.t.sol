// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {DeTrustMultisigFactory} from "../src/DeTrustMultisigFactory.sol";
//import {MockMultisigOnchainBase_01} from "../src/mock/MockMultisigOnchainBase_01.sol";
import "../src/mock/MockMultisigOnchainBase_01.sol";
import "../src/MultisigOnchainBase_01.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";
import {Helper} from "./fixtures/Helpers.sol";


// inheritors are more than allowed
contract OnchainBase_01_a_Test_03 is Test {
    
    uint256 public sendEtherAmount = 1e18;
    string public detrustName = 'NameOfDeTrust';
    //uint256 public sendERC20Amount = 2e18;
    address payable public  proxy;
    DeTrustMultisigFactory  public factory;
    //DeTrustMultisigFactory  public factory;
    MockMultisigOnchainBase_01 public impl_00;
    //eTrustModel_00 public payable impl_00_instance;
    bytes32 _digest_transfer = 0xa42d2b80860bfa2bba37a9d48246f4f2a9f02fbdeeb9b291788dbfe16da6912e;

    receive() external payable virtual {}
    function setUp() public {
        factory = new DeTrustMultisigFactory(address(0), address(0));
        impl_00 = new MockMultisigOnchainBase_01();
    }

    function test_addSigner() public {
        address[] memory _cosigners = new address[](101);
        uint64[] memory _periodOrDateArray = new uint64[](101);
        for (uint8 i = 0; i < 101; ++ i) {
            _cosigners[i] = address(100);
            _periodOrDateArray[i] = uint64(0);
        }

        // in deploy time
        vm.expectRevert('Too much inheritors');
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00),
            10, 
            _cosigners,
            _periodOrDateArray,
            detrustName, 
            keccak256("PROMO")
        ));

        address[] memory _cosigners1 = new address[](100);
        uint64[] memory _periodOrDateArray1 = new uint64[](100);
        for (uint8 i = 0; i < 99; ++ i) {
            _cosigners1[i] = address(100);
            _periodOrDateArray1[i] = uint64(0);
        }
        _cosigners1[99] = address(11);
        _periodOrDateArray1[99] = uint64(0);

        proxy = payable(factory.deployProxyForTrust(
            address(impl_00),
            2, 
            _cosigners1,
            _periodOrDateArray1,
            detrustName, 
            keccak256("PROMO")
        ));

        // in adding to cosigner time
        bytes memory _data = abi.encodeWithSignature(
            "addSigner(address,uint64)",
            address(1500), 0
        );
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);
        vm.startPrank(address(11));
        uint256 lastNonce =  multisig_instance.createAndSign(proxy, 0, _data);
        vm.stopPrank();

        vm.prank(address(100));
        vm.expectRevert('Too much inheritors');
        multisig_instance.signAndExecute(lastNonce, true);
    }
}
