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


// remove cosigner: check several cases
contract OnchainBase_01_a_Test_09 is Test, Helper {
    
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

    function test_deleteSigner() public {
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);

        vm.prank(address(11));
        vm.expectRevert('Only Self Signed');
        multisig_instance.removeSignerByIndex(2);

        bytes memory _data = abi.encodeWithSignature(
            "removeSignerByIndex(uint256)",
            2
        );
        
        MockMultisigOnchainBase_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        
        // signer creates and sign the operation
        vm.startPrank(address(11));
        uint256 expectedNonce = 0;
        vm.expectEmit();
        emit MultisigOnchainBase_01.SignatureAdded(0, address(11), 1);
        multisig_instance.createAndSign(proxy, 0, _data);
        // nonce = 0
        vm.stopPrank();

        // sign and execute
        vm.prank(address(12));
        vm.expectEmit();
        emit MultisigOnchainBase_01.SignerRemoved(MultisigOnchainBase_01.Signer(cosigner3, 0), uint8(3));
        multisig_instance.signAndExecute(0, true);
        info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.cosigners.length, 3);
        assertEq(info.cosigners[0].signer, cosigner1);
        assertEq(info.cosigners[1].signer, cosigner2);
        assertEq(info.cosigners[2].signer, cosigner4);

        // co-signer is deleted from co-signer's list. Try to sign by him. Wait revert!
        _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount/2
        );

        vm.prank(cosigner3);
        vm.expectRevert(
            abi.encodeWithSelector(MultisigOnchainBase_01.CoSignerNotExist.selector, cosigner3)
        );
        multisig_instance.createAndSign(address(erc20), 0, _data);

        // try to delete owner from co-signer's list
        _data = abi.encodeWithSignature(
            "removeSignerByIndex(uint256)",
            0
        );

        vm.prank(cosigner1);
        multisig_instance.createAndSign(proxy, 0, _data);
        // nonce = 1

        vm.prank(cosigner2);
        vm.expectRevert('Cant remove multisig owner(creator)');
        multisig_instance.signAndExecute(1, true);

        // return co-signer back to list
         _data = abi.encodeWithSignature(
            "addSigner(address,uint64)",
            cosigner3, 0
        );

        vm.startPrank(cosigner1);
        uint256 lastNonce =  multisig_instance.createAndSign(proxy, 0, _data);
        // nonce = 2
        vm.stopPrank();

        // sign and execute
        vm.prank(address(12));
        multisig_instance.signAndExecute(lastNonce, true);
        info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.cosigners.length, 4);
        assertEq(info.cosigners[3].signer, cosigner3);

        // check rights of new cosigner
        _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount/2
        );
        vm.prank(cosigner3);
        expectedNonce = 3;
        vm.expectEmit();
        emit MultisigOnchainBase_01.SignatureAdded(expectedNonce, cosigner3, 1);
        lastNonce = multisig_instance.createAndSign(address(erc20), 0, _data);
        // nonce = 3
        info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.ops[lastNonce].signedBy[0], cosigner3);



    }
}
