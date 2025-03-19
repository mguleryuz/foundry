// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {PreSaleOrchestrator_v1} from "src/PreSaleOrchestrator_v1.sol";
import {IPreSaleOrchestrator_v1} from "src/interfaces/IPreSaleOrchestrator_v1.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract StatsTest is Test {
    // Contract instance
    PreSaleOrchestrator_v1 private presale;

    // User addresses
    address private admin = address(this);
    address private user1 = makeAddr("user1");

    // Enums for easier reference
    IPreSaleOrchestrator_v1.PackageType private constant SMALL = IPreSaleOrchestrator_v1.PackageType.Small;

    function setUp() public {
        // Deploy presale contract
        presale = new PreSaleOrchestrator_v1(500, 1000, 1500, address(0));
        console.log("Presale whitelist status:", uint256(presale.getWhitelistPeriodStatus()));
    }

    function testStats() public {
        // Start whitelist period
        presale.startWhitelistPeriod();
        console.log("After starting whitelist, status:", uint256(presale.getWhitelistPeriodStatus()));

        // Get stats before adding
        IPreSaleOrchestrator_v1.PresaleStats memory statsBefore = presale.getPresaleStats();
        console.log("Before adding - Total whitelisted users:", statsBefore.totalWhitelistedUsers);
        console.log("Before adding - Total small packages:", statsBefore.totalSmallPackages);

        // Add to whitelist
        presale.addWhitelisted(user1, SMALL);

        // Stats are now updated automatically

        // Get stats after adding
        IPreSaleOrchestrator_v1.PresaleStats memory statsAfter = presale.getPresaleStats();
        console.log("After adding - Total whitelisted users:", statsAfter.totalWhitelistedUsers);
        console.log("After adding - Total small packages:", statsAfter.totalSmallPackages);

        // This should pass now
        assertEq(statsAfter.totalWhitelistedUsers, 1);
        assertEq(statsAfter.totalSmallPackages, 1);
    }
}
