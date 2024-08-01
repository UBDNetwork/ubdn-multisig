// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {DeTrustMultisigFactory} from "../../src/DeTrustMultisigFactory.sol";
import {MockMultisigOnchainBase_01} from "../../src/mock/MockMultisigOnchainBase_01.sol";
import {MockERC20} from "../../src/mock/MockERC20.sol";


contract Helper {
    address public constant addr1 = address(11);
    address public constant addr2 = address(12);
    address public constant addr3 = address(13);
    address public constant addr4 = address(14);
    uint256 public sendERC20Amount = 2e18;
    string public detrustName = 'NameOfDeTrust';
    DeTrustMultisigFactory  public factory;
    //eTrustModel_00 public payable impl_00_instance;
    //bytes32 _digest_transfer = 0xa42d2b80860bfa2bba37a9d48246f4f2a9f02fbdeeb9b291788dbfe16da6912e;


    MockERC20 public erc20;

    //receive() external payable virtual {}
    function createProxy(address _imp, uint8 _threshold, address[] memory _cosigners, uint64[] memory _periodOrDateArray) public returns(address proxy) {
        factory = new DeTrustMultisigFactory(address(0), address(0));
        //impl_00 = new MockMultisigOnchainBase_01();
        erc20 = new MockERC20('Mock ERC20 Token', 'MOCK');
        // address _implAddress, 
        // uint8 _threshold,
        // address[] memory _inheritors,
        // uint64[] memory _periodOrDateArray,
        // string memory _name,
        // bytes32  _promoHash
        
        proxy = payable(factory.deployProxyForTrust(
            _imp,
            _threshold, 
            _cosigners,
            _periodOrDateArray,
            detrustName, 
            keccak256("PROMO")
        ));
        erc20.transfer(proxy, sendERC20Amount);
    }
}
