// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "forge-std/console.sol";

import {DeTrustMultisigFactory} from "../src/DeTrustMultisigFactory.sol";
import {DeTrustMultisigOnchainModel_Free} from "../src/DeTrustMultisigOnchainModel_Free.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

import {DeTrustMultisigModelRegistry} from "../src/DeTrustMultisigModelRegistry.sol";
import {UsersDeTrustMultisigRegistry} from "../src/UsersDeTrustMultisigRegistry.sol";

contract DeTrustMultisigOnchainModel_Free_a_02 is Test {
    uint256 public sendEtherAmount = 1e18;
    uint256 public sendERC20Amount = 2e18;
    uint256 public requiredAmount = 6e18;
    string public detrustName = 'NameOfDeTrust';
    string public badDetrustName = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
    address beneficiary = address(100);
    uint8 threshold = 2;
    error AddressInsufficientBalance(address account);

    DeTrustMultisigFactory  public factory;
    DeTrustMultisigOnchainModel_Free public impl_00;
    UsersDeTrustMultisigRegistry public userReg;
    DeTrustMultisigModelRegistry public modelReg;
    address[] inheritors = new address[](5);
    uint64[] periodOrDateArray = new uint64[](5);
    bytes32  promoHash = 0x0;
    address payable proxy;

    MockERC20 public erc20;

    receive() external payable virtual {}
    function setUp() public {
        impl_00 = new DeTrustMultisigOnchainModel_Free();
        erc20 = new MockERC20('UBDN token', 'UBDN');
        modelReg = new DeTrustMultisigModelRegistry(beneficiary); 
        userReg = new UsersDeTrustMultisigRegistry();
        factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));

        vm.prank(address(this));
        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(0x01, address(0), 0 , address(0), 0)
        );
        // console.logBytes1(modelReg.isModelEnable(address(impl_00), address(1)));

        userReg.setFactoryState(address(factory), true);
        assertEq(
            uint8(modelReg.isModelEnable(address(impl_00), address(1))), 
            uint8(0x01)
        );

        // prepare data to deploy proxy
        for (uint160 i = 1; i < 6; i++) {
            inheritors[i - 1] =  address(i);
            periodOrDateArray[i - 1] = 0;
        }

        vm.startPrank(address(11));
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            promoHash
        ));
        vm.stopPrank();
    }

    // signAndExecute
    function test_proxy1() public {

        // get proxy info
        DeTrustMultisigOnchainModel_Free multisig_instance = DeTrustMultisigOnchainModel_Free(proxy);
        DeTrustMultisigOnchainModel_Free.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();

        // topup proxy
        address payable _receiver = payable(proxy);
        _receiver.transfer(sendEtherAmount);

        // move time
        vm.warp(block.timestamp + 10000);
        // withdraw ether
        bytes memory _data = "";
        vm.prank(address(1));
        // create and sign operation
        uint256 lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);

        // sign and execute
        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNonce, true);
        // check balances
        assertEq(address(15).balance, 1e18);
        assertEq(address(proxy).balance, 0);
    }

    // executeOp
    function test_proxy2() public {

        // get proxy info
        DeTrustMultisigOnchainModel_Free multisig_instance = DeTrustMultisigOnchainModel_Free(proxy);
        DeTrustMultisigOnchainModel_Free.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();

        // topup proxy
        address payable _receiver = payable(proxy);
        _receiver.transfer(sendEtherAmount);

        // withdraw ether
        bytes memory _data = "";
        vm.prank(address(1));
        // create and sign operation
        uint256 lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);

        // sign and execute
        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNonce, false);
        
        // move time
        vm.warp(block.timestamp + 10000);
        vm.prank(address(3));
        multisig_instance.executeOp(lastNonce);

        // check balances
        assertEq(address(15).balance, 1e18);
        assertEq(address(proxy).balance, 0);
    }
    
    // executeOp batch
    function test_proxy3() public {

        // get proxy info
        DeTrustMultisigOnchainModel_Free multisig_instance = DeTrustMultisigOnchainModel_Free(proxy);
        DeTrustMultisigOnchainModel_Free.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();

        // topup proxy
        erc20.transfer(address(proxy), sendERC20Amount);
        
        uint256 balanceBefore = erc20.balanceOf(beneficiary);
        uint256 balanceBefore11 = erc20.balanceOf(address(11));
        // console2.log(erc20.balanceOf(address(11)));
        bytes memory _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(11), sendERC20Amount/2
        );
        uint256[] memory nonces = new uint256[](2);
        uint256 lastNonce;

        for (uint256 i = 0; i < 2; ++ i) {
            // signer creates and sign the operation
            vm.startPrank(address(1));
            lastNonce = multisig_instance.createAndSign(address(erc20), 0, _data);
            nonces[i] = lastNonce;
            vm.stopPrank();

            // sign and execute
            vm.prank(address(2));
            multisig_instance.signAndExecute(lastNonce, false);
        }
        vm.warp(block.timestamp + 10000);

        multisig_instance.executeOp(nonces);
        // check balances
        info = multisig_instance.getMultisigOnchainBase_01();
        
        assertEq(info.ops.length, 2);
        assertEq(erc20.balanceOf(address(11)), balanceBefore11 + sendERC20Amount);
    }
}