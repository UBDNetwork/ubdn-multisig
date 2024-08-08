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


// change threshold: check several cases
contract OnchainBase_01_a_Test_14 is Test, Helper {
    
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
        address[] memory _cosigners = new address[](4);
        uint64[] memory _periodOrDateArray = new uint64[](4);

        _cosigners[0] = cosigner1;
        _cosigners[1] = cosigner2;
        _cosigners[2] = cosigner3;
        _cosigners[3] = cosigner4;
        _periodOrDateArray[0] = uint64(0);
        _periodOrDateArray[1] = uint64(0);
        _periodOrDateArray[2] = uint64(0);
        _periodOrDateArray[3] = uint64(10000);

        proxy = payable(createProxy(
            address(impl_00),
            2, 
            _cosigners,
            _periodOrDateArray
        ));
    }

    function test_changeThreshold() public {
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);

        vm.prank(cosigner1);
        vm.expectRevert('Only Self Signed');
        uint8 newThreshold = 3;
        multisig_instance.changeThreshold(newThreshold);

        bytes memory _data = abi.encodeWithSignature(
            "changeThreshold(uint8)",
            10
        );
        
        MockMultisigOnchainBase_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        
        // signer creates and sign the operation
        vm.startPrank(cosigner1);
        uint256 lastNonce = multisig_instance.createAndSign(proxy, 0, _data);
        // nonce = 0
        vm.stopPrank();

        // sign and execute - expect revert
        vm.prank(cosigner2);
        vm.expectRevert('New Threshold more than co-signers count');
        multisig_instance.signAndExecute(lastNonce, true);


        _data = abi.encodeWithSignature(
            "changeThreshold(uint8)",
            3
        );

        vm.startPrank(cosigner1);
        lastNonce = multisig_instance.createAndSign(proxy, 0, _data);
        // nonce = 1
        vm.stopPrank();

        // sign and execute
        vm.prank(cosigner2);
        multisig_instance.signAndExecute(lastNonce, true);
        info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.threshold, uint8(3));

        _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount/2
        );

        // check threshold
        vm.startPrank(cosigner1);
        lastNonce = multisig_instance.createAndSign(proxy, 0, _data);
        // nonce = 2
        vm.stopPrank();

        // sign and execute - expect revert
        vm.prank(cosigner2);
        multisig_instance.signAndExecute(lastNonce, true);
        info = multisig_instance.getMultisigOnchainBase_01();
        // not executed operation
        assertEq(uint8(info.ops[2].status), uint8(MultisigOnchainBase_01.TxStatus.WaitingForSigners));

        // try to set threshold = 0
        _data = abi.encodeWithSignature(
            "changeThreshold(uint8)",
            0
        );
        vm.startPrank(cosigner1);
        lastNonce = multisig_instance.createAndSign(proxy, 0, _data);
        // nonce = 1
        vm.stopPrank();

        // sign
        vm.prank(cosigner2);
        multisig_instance.signAndExecute(lastNonce, false);

        // sign and execute
        vm.prank(cosigner3);
        vm.expectRevert('No zero threshold');
        multisig_instance.signAndExecute(lastNonce, true);
    }
}
