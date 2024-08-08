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


// try to make co-signer count is less than threshold (deleting of )
contract OnchainBase_01_a_Test_10 is Test, Helper {
    
    address public constant cosigner1 = address(11);
    address public constant cosigner2 = address(12);
    address public constant cosigner3 = address(13);
    address public constant cosigner4 = address(14);
    uint256 public sendEtherAmount = 1e18;
    //uint256 public sendERC20Amount = 2e18;
    address payable public  proxy;
    //DeTrustMultisigFactory  public factory;
    MockMultisigOnchainBase_01 public impl_00;
    //eTrustModel_00 public payable impl_00_instance;
    bytes32 _digest_transfer = 0xa42d2b80860bfa2bba37a9d48246f4f2a9f02fbdeeb9b291788dbfe16da6912e;

    receive() external payable virtual {}
    function setUp() public {
        //factory = new DeTrustMultisigFactory(address(0), address(0));
        impl_00 = new MockMultisigOnchainBase_01();
        address[] memory _cosigners = new address[](2);
        uint64[] memory _periodOrDateArray = new uint64[](2);

        _cosigners[0] = cosigner1;
        _cosigners[1] = cosigner2;
        _periodOrDateArray[0] = uint64(0);
        _periodOrDateArray[1] = uint64(0);

        proxy = payable(createProxy(
            address(impl_00),
            2, 
            _cosigners,
            _periodOrDateArray
        ));
    }

    function test_deleteSigner() public {
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);

        bytes memory _data = abi.encodeWithSignature(
            "removeSignerByIndex(uint256)",
            1
        );
       
        // signer creates and sign the operation
        vm.startPrank(cosigner1);
        multisig_instance.createAndSign(proxy, 0, _data);
        vm.stopPrank();

        // sign and execute
        vm.prank(cosigner2);
        vm.expectRevert('New Signers count less then threshold');
        multisig_instance.signAndExecute(0, true);  
    }
}
