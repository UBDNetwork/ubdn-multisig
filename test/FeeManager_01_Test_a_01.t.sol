// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "../src/mock/MockFeeManager_01.sol";
import "../src/FeeManager_01.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";



// non-cosigner tries to sign and execute operation
contract FeeManager_01_a_Test_01 is Test {
    
    
    uint256 public sendEtherAmount = 1e18;
    uint256 public feeAmount = 1e18;
    uint64 public currentTime;
    //uint256 public sendERC20Amount = 2e18;
    MockFeeManager_01  public feeM;
    MockERC20 public erc20;
    //eTrustModel_00 public payable impl_00_instance;
    

    receive() external payable virtual {}
    function setUp() public {
        feeM = new MockFeeManager_01();
        erc20 = new MockERC20('Mock ERC20 Token', 'MOCK');
        feeM.initialize(
            address(erc20), // fee token
            feeAmount,
            address(11), // beneficiary
            0); // paied till
        currentTime = uint64(block.timestamp);
    }


    // one period
    function test_chargeFee1() public {
        erc20.transfer(address(feeM), feeAmount);

        MockFeeManager_01.FeeManager_01_Storage memory info = feeM.geFeeManager_01_StorageInfo();
        assertEq(info.fee.payedTill, currentTime + feeM.ANNUAL_FEE_PERIOD());
        vm.startPrank(address(1));
        uint64 period = 1;
        uint64 payedTillBefore = info.fee.payedTill;
        feeM.chargeFee(period);
        vm.stopPrank();
        info = feeM.geFeeManager_01_StorageInfo();
        assertEq(info.fee.payedTill, payedTillBefore + feeM.ANNUAL_FEE_PERIOD());
        assertEq(feeM.isAnnualFeePayed(), true);
    }

     // several periods
    function test_chargeFee2() public {
        uint64 period = 3;
        erc20.transfer(address(feeM), feeAmount * period);

        MockFeeManager_01.FeeManager_01_Storage memory info = feeM.geFeeManager_01_StorageInfo();
        vm.startPrank(address(1));
        
        uint64 payedTillBefore = info.fee.payedTill;
        feeM.chargeFee(period);
        vm.stopPrank();
        info = feeM.geFeeManager_01_StorageInfo();
        assertEq(info.fee.payedTill, payedTillBefore + feeM.ANNUAL_FEE_PERIOD() * period);
        assertEq(feeM.isAnnualFeePayed(), true);
    }
}