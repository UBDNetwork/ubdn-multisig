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
import {MultisigOnchainBase_01} from "../src/MultisigOnchainBase_01.sol";

// create trust and withdwaw eth from trust
contract DeTrustMultisigOnchainModel_Free_a_01 is Test {
    uint256 public sendEtherAmount = 1e18;
    uint256 public sendERC20Amount = 2e18;
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
    MockERC20 public erc20Hold;

    receive() external payable virtual {}
    function setUp() public {
        impl_00 = new DeTrustMultisigOnchainModel_Free();
        erc20 = new MockERC20('UBDN token', 'UBDN');
        modelReg = new DeTrustMultisigModelRegistry(beneficiary); 
        userReg = new UsersDeTrustMultisigRegistry();
        factory = new DeTrustMultisigFactory(address(modelReg), address(userReg));

        // with fee to create trust - but fee is not being charged
        vm.prank(address(this));
        modelReg.setModelState(
            address(impl_00),
            DeTrustMultisigModelRegistry.TrustModel(0x01, address(0), 0, address(0), 0)
        );
        

        // set hold token contract - but balance is not being used
        modelReg.setMinHoldAddress(address(erc20Hold));
        
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
        //setup silent period for address(5)
        periodOrDateArray[4] = 100000;
    }

    // 
    function test_proxy() public {
        assertEq(address(factory.modelRegistry()), address(modelReg));
        assertEq(address(factory.trustRegistry()), address(userReg));

        // send transaction from address(1) - balance is zero, expect revert

        // use too long name - expect revert
        vm.prank(address(1));
        vm.expectRevert("Too long name");
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00), 
            threshold,
            inheritors,
            periodOrDateArray,
            badDetrustName,
            promoHash
        ));

        vm.startPrank(address(11));
        // deploy proxy
        proxy = payable(factory.deployProxyForTrust(
            address(impl_00), 
            threshold,
            inheritors,
            periodOrDateArray,
            detrustName,     //_name
            promoHash
        ));

        assertEq(userReg.getCreatorTrusts(address(1))[0], proxy);

        vm.stopPrank();
        
        // get proxy info
        DeTrustMultisigOnchainModel_Free multisig_instance = DeTrustMultisigOnchainModel_Free(proxy);
        DeTrustMultisigOnchainModel_Free.MultisigOnchainBase_01_Storage memory info = multisig_instance.getMultisigOnchainBase_01();
        
        assertEq(info.ops.length, 0);
        assertEq(info.threshold, threshold);
        assertEq(info.cosigners.length, 5);
        assertEq(info.cosigners[4].validFrom, 0); // check cosigner 4


        // check UsersDeTrustRegistry
        assertEq(userReg.getInheritorTrusts(address(1))[0], proxy);
        assertEq(userReg.getInheritorTrusts(address(5))[0], proxy);

        
        // topup trust
        erc20.transfer(proxy, sendERC20Amount);
        address payable _receiver = payable(proxy);
        _receiver.transfer(sendEtherAmount);

        // move time
        vm.warp(block.timestamp + 100);
        // withdraw ether
        bytes memory _data = "";
        vm.prank(address(1));
        // create and sign operation
        uint256 lastNonce = multisig_instance.createAndSign(address(15), 1e18, _data);

        // non-cosigner tries to add the signature
        vm.prank(address(10));
        vm.expectRevert(
            abi.encodeWithSelector(MultisigOnchainBase_01.CoSignerNotExist.selector, address(10))
        );
        multisig_instance.signAndExecute(lastNonce, true);

        // sign and execute - cosigner
        vm.prank(address(2));
        multisig_instance.signAndExecute(lastNonce, true);
        // check balances
        assertEq(address(15).balance, 1e18);
        assertEq(address(proxy).balance, 0);
        info = multisig_instance.getMultisigOnchainBase_01();
        
        assertEq(info.ops.length, 1);
        assertEq(info.ops[0].signedBy.length, 2);
    }
}