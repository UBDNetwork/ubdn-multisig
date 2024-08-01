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
    error TxStatusError(MultisigOnchainBase_01.TxStatus status);

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
            2, 
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
        lastNonce =  multisig_instance.createAndSign(proxy, 0, _data);
        vm.stopPrank();

        MockMultisigOnchainBase_01.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        assertEq(info.ops.length, lastNonce + 1);
        assertEq(info.ops[0].metaTx, _data);
        assertEq(info.ops[0].signedBy[0], address(11));
        assertEq(uint8(info.ops[0].status), 0);
        // if (info.ops[0].status != MultisigOnchainBase_01.TxStatus.WaitingForSigners) {
        //     revert TxStatusError(info.ops[0].status);
        // }
        
        // signer 
    }

    /*function test_proxyAddress() public view {
        assertEq(address(factory.modelRegistry()), address(0));
        assertEq(address(factory.trustRegistry()), address(0));
        console2.log("Implementation   addr: %s", address(impl_00));
        console2.log("Proxy for     impl_00: %s", proxy);
        assertFalse(address(impl_00) == proxy);
        assertEq(erc20.balanceOf(proxy), sendERC20Amount);
    }*/
}
