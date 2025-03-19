// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PreSaleOrchestrator_v1} from "src/PreSaleOrchestrator_v1.sol";
import {IPreSaleOrchestrator_v1} from "src/interfaces/IPreSaleOrchestrator_v1.sol";

contract DirectStatsTest is Test {
    PreSaleOrchestrator_v1 public presale;

    function setUp() public {
        presale = new PreSaleOrchestrator_v1();
    }

    function testDirectStatsUpdate() public {
        // Get initial stats
        IPreSaleOrchestrator_v1.PresaleStats memory statsBefore = presale.getPresaleStats();
        console.log("Initial users:", statsBefore.totalWhitelistedUsers);
        console.log("Initial small:", statsBefore.totalSmallPackages);

        // Update stats directly
        presale.updateStatsDirectly(10, 5, 3, 2);

        // Get updated stats
        IPreSaleOrchestrator_v1.PresaleStats memory statsAfter = presale.getPresaleStats();
        console.log("After update - users:", statsAfter.totalWhitelistedUsers);
        console.log("After update - small:", statsAfter.totalSmallPackages);
        console.log("After update - medium:", statsAfter.totalMediumPackages);
        console.log("After update - large:", statsAfter.totalLargePackages);

        // Verify updates
        assertEq(statsAfter.totalWhitelistedUsers, 10);
        assertEq(statsAfter.totalSmallPackages, 5);
        assertEq(statsAfter.totalMediumPackages, 3);
        assertEq(statsAfter.totalLargePackages, 2);
    }
}
