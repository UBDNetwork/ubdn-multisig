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


contract OnchainBase_01_a_Test_01 is Test, Helper {
    
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
    }

    function test_addSigner() public {
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
            3, 
            _cosigners,
            _periodOrDateArray
        ));

        // attemp is fail - direct call of contract methods
        vm.prank(address(11));
        vm.expectRevert('Only Self Signed');
        bytes memory _returnData = Address.functionCall(proxy, abi.encodeWithSignature(
            "addSigner(address,uint64)",
            address(15), 0
        ));


        bytes memory _data = abi.encodeWithSignature(
            "addSigner(address,uint64)",
            address(15), 0
        );
       
        MockMultisigOnchainBase_01 multisig_instance = MockMultisigOnchainBase_01(proxy);
        // non-signer tries to create the operation - wait revert
        vm.startPrank(address(15));
        vm.expectRevert(
            abi.encodeWithSelector(MultisigOnchainBase_01.CoSignerNotExist.selector, address(15))
        );
        uint256 lastNonce =  multisig_instance.createAndSign(proxy, 0, _data);
        vm.stopPrank();

        // signer creates and sign the operation
        vm.startPrank(address(11));
        vm.expectEmit();
        uint256 expectedNonce = 0;
        emit MultisigOnchainBase_01.SignatureAdded(expectedNonce, address(11), 1);
        lastNonce =  multisig_instance.createAndSign(proxy, 0, _data);
        vm.stopPrank();

        MockMultisigOnchainBase_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.ops.length, lastNonce + 1);
        assertEq(info.ops[0].metaTx, _data);
        assertEq(info.ops[0].signedBy[0], address(11));
        assertEq(uint8(info.ops[0].status), uint8(MultisigOnchainBase_01.TxStatus.WaitingForSigners));

        // signer only signs tx
        vm.prank(address(12));
        emit MultisigOnchainBase_01.SignatureAdded(expectedNonce, address(12), 2);
        uint256 signedByCount = multisig_instance.signAndExecute(lastNonce, false);
        info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(signedByCount, 2);
        assertEq(info.ops.length, lastNonce + 1);
        assertEq(info.ops[0].signedBy[1], address(12));
        assertEq(uint8(info.ops[0].status), uint8(MultisigOnchainBase_01.TxStatus.WaitingForSigners));

        // signer signs and executes tx
        vm.prank(address(13));
        emit MultisigOnchainBase_01.SignatureAdded(expectedNonce, address(13), 3);
        emit MultisigOnchainBase_01.TxExecuted(expectedNonce, address(13));
        signedByCount = multisig_instance.signAndExecute(lastNonce, true);
        info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(signedByCount, 3);
        assertEq(info.ops.length, lastNonce + 1);
        assertEq(info.ops[0].signedBy[2], address(13));
        assertEq(uint8(info.ops[0].status), uint8(MultisigOnchainBase_01.TxStatus.Executed));
        assertEq(info.cosigners[info.cosigners.length - 1].signer, address(15)); // check new cosigner

        // try to add the signer again (he has already been in cosigner's list)
        vm.startPrank(address(11));
        vm.expectEmit();
        expectedNonce = 1;
        emit MultisigOnchainBase_01.SignatureAdded(expectedNonce, address(11), 1);
        lastNonce =  multisig_instance.createAndSign(proxy, 0, _data);
        vm.stopPrank();

        vm.prank(address(12));
        multisig_instance.signAndExecute(lastNonce, false);

        vm.prank(address(13));
        vm.expectRevert(
            abi.encodeWithSelector(MultisigOnchainBase_01.CoSignerAlreadyExist.selector, address(15))
        );
        multisig_instance.signAndExecute(lastNonce, true);

        // try to sign executed tx - wait fail
        vm.prank(address(14));
        vm.expectRevert(
            abi.encodeWithSelector(MultisigOnchainBase_01.CoSignerAlreadyExist.selector, address(15))
        );
        signedByCount = multisig_instance.signAndExecute(lastNonce, true);

        vm.prank(address(13));
        vm.expectRevert(
            abi.encodeWithSelector(MultisigOnchainBase_01.CoSignerAlreadyExist.selector, address(15))
        );
        signedByCount = multisig_instance.signAndExecute(lastNonce, true);
    }
}
