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


// revoke signature
contract OnchainBase_01_a_Test_12 is Test, Helper {
    
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

    // consistently revoke signatures and reject the operation
    // non-signer of operation tries to revoke signature - nothing has to happen
    function test_revokeSignature1() public {
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);
        
        MockMultisigOnchainBase_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        
        bytes memory _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount/2
        );

        vm.prank(cosigner1);
        uint256 lastNonce = multisig_instance.createAndSign(address(erc20), 0, _data);
        // nonce = 0

        vm.prank(cosigner2);
        multisig_instance.signAndExecute(lastNonce, false);

        // non-signer of operation tries to revoke signature - nothing has to happen
        vm.prank(cosigner3);
        multisig_instance.revokeSignature(lastNonce, false);

        // signer of operation revokes the signature
        vm.prank(cosigner1);
        vm.expectEmit();
        emit MultisigOnchainBase_01.SignatureRevoked(
            lastNonce,
            cosigner1,
            1);
        multisig_instance.revokeSignature(lastNonce, false);
        info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.ops[lastNonce].signedBy.length, 1);
        assertEq(info.ops[lastNonce].signedBy[0], cosigner2);

        // signer of operation revokes  the signature and reject the operation
        vm.prank(cosigner2);
        vm.expectEmit();
        emit MultisigOnchainBase_01.SignatureRevoked(
            lastNonce,
            cosigner2,
            0);
        emit MultisigOnchainBase_01.TxRejected(
            lastNonce,
            cosigner2);
        multisig_instance.revokeSignature(lastNonce, true);
        info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.ops.length, 1);
        assertEq(uint8(info.ops[0].status), uint8(MultisigOnchainBase_01.TxStatus.Rejected));
    }

    // the operation is EXECUTED
    function test_revokeSignature2() public {
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);
        
        //MockMultisigOnchainBase_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        
        bytes memory _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount/2
        );

        vm.prank(cosigner1);
        uint256 lastNonce = multisig_instance.createAndSign(address(erc20), 0, _data);
        // nonce = 0

        vm.prank(cosigner2);
        multisig_instance.signAndExecute(lastNonce, true);

        // non-signer of operation tries to revoke signature - nothing has to happen
        vm.prank(cosigner3);
        vm.expectRevert(
            abi.encodeWithSelector(
                MultisigOnchainBase_01.ActionDeniedForThisStatus.selector, 
                uint8(MultisigOnchainBase_01.TxStatus.Executed))
        );
        multisig_instance.revokeSignature(lastNonce, false);

        // signer of operation tries to revoke the signature - without reject
        vm.prank(cosigner1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MultisigOnchainBase_01.ActionDeniedForThisStatus.selector, 
                uint8(MultisigOnchainBase_01.TxStatus.Executed))
        );
        multisig_instance.revokeSignature(lastNonce, false);

        // signer of operation tries to revoke the signature - with reject
        vm.prank(cosigner1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MultisigOnchainBase_01.ActionDeniedForThisStatus.selector, 
                uint8(MultisigOnchainBase_01.TxStatus.Executed))
        );
        multisig_instance.revokeSignature(lastNonce, true);
    }
}
