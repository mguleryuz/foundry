// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PreSaleOrchestrator_v1} from "../src/PreSaleOrchestrator_v1.sol";
import {IPreSaleOrchestrator_v1} from "../src/interfaces/IPreSaleOrchestrator_v1.sol";

contract SimpleStatsTest is Test {
    PreSaleOrchestrator_v1 public presale;

    address public user1 = makeAddr("user1");

    IPreSaleOrchestrator_v1.PackageType private constant SMALL = IPreSaleOrchestrator_v1.PackageType.Small;

    function setUp() public {
        presale = new PreSaleOrchestrator_v1();
        presale.startWhitelistPeriod(); // Start whitelist period
    }

    function testSimpleAddWhitelisted() public {
        uint256 beforeUsers = presale.getPresaleStats().totalWhitelistedUsers;
        uint256 beforeSmall = presale.getPresaleStats().totalSmallPackages;

        console.log("Before - Users:", beforeUsers);
        console.log("Before - Small:", beforeSmall);

        // Add user status
        presale.addWhitelisted(user1, SMALL);

        // Update stats manually
        presale.updateStatsDirectly(beforeUsers + 1, beforeSmall + 1, 0, 0);

        uint256 afterUsers = presale.getPresaleStats().totalWhitelistedUsers;
        uint256 afterSmall = presale.getPresaleStats().totalSmallPackages;

        console.log("After - Users:", afterUsers);
        console.log("After - Small:", afterSmall);

        assertEq(afterUsers, beforeUsers + 1);
        assertEq(afterSmall, beforeSmall + 1);
    }
}
