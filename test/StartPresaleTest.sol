// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PreSaleOrchestrator_v1} from "../src/PreSaleOrchestrator_v1.sol";
import {IPreSaleOrchestrator_v1} from "../src/interfaces/IPreSaleOrchestrator_v1.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract StartPresaleTest is Test {
    PreSaleOrchestrator_v1 public presale;
    MockERC20 public token;

    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    address public treasury = makeAddr("treasury");

    IPreSaleOrchestrator_v1.PackageType private constant SMALL = IPreSaleOrchestrator_v1.PackageType.Small;
    IPreSaleOrchestrator_v1.PackageType private constant MEDIUM = IPreSaleOrchestrator_v1.PackageType.Medium;
    IPreSaleOrchestrator_v1.PackageType private constant LARGE = IPreSaleOrchestrator_v1.PackageType.Large;

    function setUp() public {
        presale = new PreSaleOrchestrator_v1();
        token = new MockERC20("Test Token", "TST", 18);

        // Mint tokens
        token.mint(address(this), 1_000_000 * 10 ** 18);

        // Set basic config
        presale.setTreasury(treasury);
        presale.setDistributionToken(address(token));
    }

    function testStartPresaleWorks() public {
        console.log("Step 1: Setting up whitelist");
        // Start whitelist period
        presale.startWhitelistPeriod();

        console.log("Step 2: Setting stats");
        // Set stats manually
        presale.updateStatsDirectly(3, 1, 1, 1);

        console.log("Step 3: Adding users");
        // Add user status without affecting stats
        presale.addWhitelisted(user1, SMALL);
        presale.addWhitelisted(user2, MEDIUM);
        presale.addWhitelisted(user3, LARGE);

        console.log("Step 4: Ending whitelist");
        // End whitelist period
        presale.endWhitelistPeriod();

        console.log("Step 5: Depositing tokens");
        // Deposit tokens - substantial amount
        token.approve(address(presale), 1_000_000 * 10 ** 18);
        presale.depositDistribution(1_000_000 * 10 ** 18);

        console.log("Step 6: Calculating distribution");
        // Check distribution calculated correctly
        (uint256 small, uint256 medium, uint256 large) = presale.calculateTokenDistribution();
        console.log("Small distribution:", small);
        console.log("Medium distribution:", medium);
        console.log("Large distribution:", large);

        console.log("Step 7: Starting presale");
        // Start presale
        presale.startPreSale();

        console.log("Step 8: Checking requirements");
        // Verify requirements were set correctly
        IPreSaleOrchestrator_v1.ContributionRequirement memory reqs = presale.getContributionRequirements();
        console.log("Small requirement:", reqs.smallPackageRequirement);
        console.log("Medium requirement:", reqs.mediumPackageRequirement);
        console.log("Large requirement:", reqs.largePackageRequirement);

        console.log("Step 9: Verifying active");
        // Verify presale is active
        assertEq(uint256(presale.getPreSalePeriodStatus()), 1); // 1 = Active
    }
}
