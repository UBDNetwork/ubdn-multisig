// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {PromoManagerV0} from "../src/PromoManagerV0.sol";

contract PromoManager_00_Test is Test {
    string public publicPromo = 'PUBLIC';
    string public privatePromo = 'PRIVATE';
    PromoManagerV0 public promoM;

    receive() external payable virtual {}
    function setUp() public {
        promoM = new PromoManagerV0();
        promoM.setPromoPeriodForExactUser(
            promoM.hlpGetPromoHash(privatePromo),
            PromoManagerV0.PromoPeriod(block.timestamp + 600, uint64(60)),
            address(1)
        );
        promoM.setPromoPeriod(
            promoM.hlpGetPromoHash(publicPromo),
            PromoManagerV0.PromoPeriod(block.timestamp + 300, uint64(30))
        );

    }

    // function test_failUnAuth() public {
    //     vm.startPrank(address(55));
    //     vm.expectRevert();
    //     //vm.prank(address(55));
    //     promoM.setPromoPeriodForExactUser(
    //         promoM.hlpGetPromoHash(privatePromo),
    //         PromoManagerV0.PromoPeriod(block.timestamp + 700, uint64(70)),
    //         address(1)
    //     );

    // }


    function test_checkPromos() public view {
        assertEq(
            promoM.getPrepaidPeriod(address(0), address(1),promoM.hlpGetPromoHash(privatePromo)), 
            uint64(60)
        );
        assertEq(
            promoM.getPrepaidPeriod(address(0), address(2),promoM.hlpGetPromoHash(privatePromo)), 
            uint64(0)
        );
        assertEq(
            promoM.getPrepaidPeriod(address(0), address(1),promoM.hlpGetPromoHash(publicPromo)), 
            uint64(30)
        );
        assertEq(
            promoM.getPrepaidPeriod(address(0), address(1),promoM.hlpGetPromoHash(publicPromo)), 
            promoM.getPrepaidPeriod(address(0), address(2),promoM.hlpGetPromoHash(publicPromo))
        );
        assertEq(
            promoM.getPrepaidPeriod(address(0), address(1),promoM.hlpGetPromoHash("FAKEPROMO")), 
            uint64(0)
        );
        assertEq(
            promoM.getPrepaidPeriod(address(0), address(2),promoM.hlpGetPromoHash("FAKEPROMO")), 
            uint64(0)
        );

   }
}
