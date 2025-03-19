// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PreSaleOrchestrator_v1} from "src/PreSaleOrchestrator_v1.sol";
import {IPreSaleOrchestrator_v1} from "src/interfaces/IPreSaleOrchestrator_v1.sol";

contract SimpleStatsTest is Test {
    PreSaleOrchestrator_v1 public presale;

    address public user1 = makeAddr("user1");

    IPreSaleOrchestrator_v1.PackageType private constant SMALL = IPreSaleOrchestrator_v1.PackageType.Small;

    // ProcessStatus enum values
    uint256 private constant INACTIVE = 0;
    uint256 private constant ACTIVE = 1;
    uint256 private constant PAUSED = 2;
    uint256 private constant ENDED = 3;

    function setUp() public {
        presale = new PreSaleOrchestrator_v1();

        // Check initial status
        uint256 initialStatus = uint256(presale.getWhitelistPeriodStatus());
        console.log("Initial whitelist status:", initialStatus);

        presale.startWhitelistPeriod(); // Start whitelist period

        // Check status after starting
        uint256 afterStartStatus = uint256(presale.getWhitelistPeriodStatus());
        console.log("Whitelist status after start:", afterStartStatus);

        // Verify whitelist is active
        assertEq(afterStartStatus, ACTIVE, "Whitelist should be active after startWhitelistPeriod");
    }

    function testSimpleAddWhitelisted() public {
        // Verify whitelist status is active
        uint256 status = uint256(presale.getWhitelistPeriodStatus());
        console.log("Whitelist status at test start:", status);
        assertEq(status, ACTIVE, "Whitelist should be active");

        uint256 beforeUsers = presale.getPresaleStats().totalWhitelistedUsers;
        uint256 beforeSmall = presale.getPresaleStats().totalSmallPackages;

        console.log("Before - Users:", beforeUsers);
        console.log("Before - Small:", beforeSmall);

        // Add user status
        presale.addWhitelisted(user1, SMALL);

        // Check user status after whitelisting
        IPreSaleOrchestrator_v1.User memory user = presale.getUser(user1);
        console.log("User status:", uint256(user.status));
        console.log("User package type:", uint256(user.packageType));

        // Stats are now updated automatically
        uint256 afterUsers = presale.getPresaleStats().totalWhitelistedUsers;
        uint256 afterSmall = presale.getPresaleStats().totalSmallPackages;

        console.log("After - Users:", afterUsers);
        console.log("After - Small:", afterSmall);

        assertEq(afterUsers, beforeUsers + 1, "Total users should increase by 1");
        assertEq(afterSmall, beforeSmall + 1, "Small packages should increase by 1");
    }
}
