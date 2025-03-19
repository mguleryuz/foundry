// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PreSaleOrchestrator_v1} from "src/PreSaleOrchestrator_v1.sol";
import {IPreSaleOrchestrator_v1} from "src/interfaces/IPreSaleOrchestrator_v1.sol";

contract DirectStatsTest is Test {
    PreSaleOrchestrator_v1 public presale;

    address private user1 = makeAddr("user1");
    address private user2 = makeAddr("user2");
    address private user3 = makeAddr("user3");

    // Enum shortcuts
    IPreSaleOrchestrator_v1.PackageType private constant SMALL = IPreSaleOrchestrator_v1.PackageType.Small;
    IPreSaleOrchestrator_v1.PackageType private constant MEDIUM = IPreSaleOrchestrator_v1.PackageType.Medium;
    IPreSaleOrchestrator_v1.PackageType private constant LARGE = IPreSaleOrchestrator_v1.PackageType.Large;

    function setUp() public {
        presale = new PreSaleOrchestrator_v1(5 ether, 10 ether, 15 ether, address(0));
        presale.startWhitelistPeriod();
    }

    function testAutomaticStatsUpdate() public {
        // Get initial stats
        IPreSaleOrchestrator_v1.PresaleStats memory statsBefore = presale.getPresaleStats();
        console.log("Initial users:", statsBefore.totalWhitelistedUsers);
        console.log("Initial small:", statsBefore.totalSmallPackages);

        // Add users with different package types
        presale.addWhitelisted(user1, SMALL);
        presale.addWhitelisted(user2, MEDIUM);
        presale.addWhitelisted(user3, LARGE);

        // Get updated stats
        IPreSaleOrchestrator_v1.PresaleStats memory statsAfter = presale.getPresaleStats();
        console.log("After adding - users:", statsAfter.totalWhitelistedUsers);
        console.log("After adding - small:", statsAfter.totalSmallPackages);
        console.log("After adding - medium:", statsAfter.totalMediumPackages);
        console.log("After adding - large:", statsAfter.totalLargePackages);

        // Verify updates
        assertEq(statsAfter.totalWhitelistedUsers, 3);
        assertEq(statsAfter.totalSmallPackages, 1);
        assertEq(statsAfter.totalMediumPackages, 1);
        assertEq(statsAfter.totalLargePackages, 1);

        // Test changing package type
        presale.addWhitelisted(user1, MEDIUM);

        // Get stats after change
        IPreSaleOrchestrator_v1.PresaleStats memory statsChange = presale.getPresaleStats();
        console.log("After changing user1 to medium - small:", statsChange.totalSmallPackages);
        console.log("After changing user1 to medium - medium:", statsChange.totalMediumPackages);

        // Verify package counts updated
        assertEq(statsChange.totalWhitelistedUsers, 3); // No change in total
        assertEq(statsChange.totalSmallPackages, 0); // Decreased by 1
        assertEq(statsChange.totalMediumPackages, 2); // Increased by 1

        // Test removing user
        presale.removeWhitelisted(user3);

        // Get stats after removal
        IPreSaleOrchestrator_v1.PresaleStats memory statsRemoval = presale.getPresaleStats();
        console.log("After removing user3 - users:", statsRemoval.totalWhitelistedUsers);
        console.log("After removing user3 - large:", statsRemoval.totalLargePackages);

        // Verify removal updates
        assertEq(statsRemoval.totalWhitelistedUsers, 2); // Decreased by 1
        assertEq(statsRemoval.totalLargePackages, 0); // Decreased by 1
    }
}
