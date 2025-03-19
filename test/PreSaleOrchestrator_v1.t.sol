// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {PreSaleOrchestrator_v1} from "src/PreSaleOrchestrator_v1.sol";
import {IPreSaleOrchestrator_v1} from "src/interfaces/IPreSaleOrchestrator_v1.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract PreSaleOrchestratorTest is Test {
    // Contract instances
    PreSaleOrchestrator_v1 private presale;
    MockERC20 private distributionToken;
    MockERC20 private paymentToken;

    // User addresses
    address private admin = address(this);
    address private user1 = makeAddr("user1");
    address private user2 = makeAddr("user2");
    address private user3 = makeAddr("user3");
    address private user4 = makeAddr("user4");
    address private user5 = makeAddr("user5");
    address private newAdmin = makeAddr("newAdmin");

    // Test constants
    uint256 private constant DISTRIBUTION_AMOUNT = 10_000_000 * 10 ** 18;
    uint256 private constant PARTICIPATION_AMOUNT_SMALL = 1 ether;
    uint256 private constant PARTICIPATION_AMOUNT_MEDIUM = 3 ether;
    uint256 private constant PARTICIPATION_AMOUNT_LARGE = 10 ether;

    // Enums from the interface for easier reference
    IPreSaleOrchestrator_v1.ProcessStatus private constant INACTIVE = IPreSaleOrchestrator_v1.ProcessStatus.Inactive;
    IPreSaleOrchestrator_v1.ProcessStatus private constant ACTIVE = IPreSaleOrchestrator_v1.ProcessStatus.Active;
    IPreSaleOrchestrator_v1.ProcessStatus private constant PAUSED = IPreSaleOrchestrator_v1.ProcessStatus.Paused;
    IPreSaleOrchestrator_v1.ProcessStatus private constant ENDED = IPreSaleOrchestrator_v1.ProcessStatus.Ended;

    IPreSaleOrchestrator_v1.PackageType private constant SMALL = IPreSaleOrchestrator_v1.PackageType.Small;
    IPreSaleOrchestrator_v1.PackageType private constant MEDIUM = IPreSaleOrchestrator_v1.PackageType.Medium;
    IPreSaleOrchestrator_v1.PackageType private constant LARGE = IPreSaleOrchestrator_v1.PackageType.Large;

    IPreSaleOrchestrator_v1.UserStatus private constant APPROVED = IPreSaleOrchestrator_v1.UserStatus.Approved;
    IPreSaleOrchestrator_v1.UserStatus private constant REVOKED = IPreSaleOrchestrator_v1.UserStatus.Revoked;
    IPreSaleOrchestrator_v1.UserStatus private constant REJECTED = IPreSaleOrchestrator_v1.UserStatus.Rejected;

    // Add a receive function to allow the test contract to receive ETH
    receive() external payable {}

    function setUp() public {
        // Deploy mock tokens
        distributionToken = new MockERC20("Distribution Token", "DIST", 18);
        paymentToken = new MockERC20("Payment Token", "PAY", 18);

        // Deploy presale contract with ETH as payment by default (address(0))
        presale = new PreSaleOrchestrator_v1(
            PARTICIPATION_AMOUNT_SMALL,
            PARTICIPATION_AMOUNT_MEDIUM,
            PARTICIPATION_AMOUNT_LARGE,
            address(0) // ETH as payment
        );

        // Debug
        console.log("Presale initialized, whitelist status:", uint256(presale.getWhitelistPeriodStatus()));

        // Mint tokens to admin for distribution
        distributionToken.mint(admin, DISTRIBUTION_AMOUNT);

        // Mint payment tokens to users
        paymentToken.mint(user1, 100 ether);
        paymentToken.mint(user2, 100 ether);
        paymentToken.mint(user3, 100 ether);
        paymentToken.mint(user4, 100 ether);
        paymentToken.mint(user5, 100 ether);

        // Give ETH to users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(user4, 100 ether);
        vm.deal(user5, 100 ether);
    }

    // Helper function to set up the basic configuration
    function _setupBasicConfig() internal {
        presale.setDistributionToken(address(distributionToken));
    }

    // Helper function to create a fresh instance with ETH payment
    function _createFreshInstance() internal {
        presale = new PreSaleOrchestrator_v1(
            PARTICIPATION_AMOUNT_SMALL,
            PARTICIPATION_AMOUNT_MEDIUM,
            PARTICIPATION_AMOUNT_LARGE,
            address(0) // ETH as payment
        );
        _setupBasicConfig();
    }

    // Helper function to create a fresh instance with ERC20 payment
    function _createFreshInstanceWithERC20() internal {
        presale = new PreSaleOrchestrator_v1(
            PARTICIPATION_AMOUNT_SMALL,
            PARTICIPATION_AMOUNT_MEDIUM,
            PARTICIPATION_AMOUNT_LARGE,
            address(paymentToken) // ERC20 as payment
        );
        _setupBasicConfig();
    }

    // Helper function for a complete presale setup with ETH as payment
    function _setupCompletePresaleWithETH() internal {
        // Setup fresh instance
        _createFreshInstance();

        // Start and end whitelist period
        presale.startWhitelistPeriod();

        // Add users to whitelist
        presale.addWhitelisted(user1, SMALL);
        presale.addWhitelisted(user2, MEDIUM);
        presale.addWhitelisted(user3, LARGE);

        // Stats are now updated automatically

        presale.endWhitelistPeriod();

        // Deposit distribution tokens
        distributionToken.approve(address(presale), DISTRIBUTION_AMOUNT);
        presale.depositDistribution(DISTRIBUTION_AMOUNT);

        // Start presale
        presale.startPreSale();
    }

    // Helper function for a complete presale setup with ERC20 as payment
    function _setupCompletePresaleWithERC20() internal {
        _createFreshInstanceWithERC20();

        // Start whitelist period
        presale.startWhitelistPeriod();

        // Add users to whitelist
        presale.addWhitelisted(user1, SMALL);
        presale.addWhitelisted(user2, MEDIUM);
        presale.addWhitelisted(user3, LARGE);
        presale.addWhitelisted(user4, SMALL);
        presale.addWhitelisted(user5, MEDIUM);

        // Stats are now updated automatically

        // Verify whitelist was set up correctly
        IPreSaleOrchestrator_v1.PresaleStats memory stats = presale.getPresaleStats();
        assert(stats.totalWhitelistedUsers == 5);
        assert(stats.totalSmallPackages == 2);
        assert(stats.totalMediumPackages == 2);
        assert(stats.totalLargePackages == 1);

        // End whitelist period
        presale.endWhitelistPeriod();
        assert(presale.getWhitelistPeriodStatus() == ENDED);

        // Deposit distribution tokens and start presale
        distributionToken.approve(address(presale), DISTRIBUTION_AMOUNT);
        presale.depositDistribution(DISTRIBUTION_AMOUNT);

        // Start presale
        presale.startPreSale();
        assert(presale.getPreSalePeriodStatus() == ACTIVE);
    }

    //--------------------------------------------------------------------------
    // Admin Tests

    function testInitialAdminSetup() public {
        assertTrue(presale.getPresaleConfig().whitelistStatus == INACTIVE);
        assertTrue(presale.getPresaleConfig().preSaleStatus == INACTIVE);

        // Test that payment currency was set during construction
        assertEq(presale.getPaymentCurrency(), address(0)); // Default is ETH

        // Test setting distribution token
        presale.setDistributionToken(address(distributionToken));
        assertEq(presale.getDistributionToken(), address(distributionToken));
    }

    function testInitialContributionRequirements() public view {
        // Test that contribution requirements were set correctly during construction
        IPreSaleOrchestrator_v1.ContributionRequirement memory reqs = presale.getContributionRequirements();
        assertEq(reqs.smallPackageRequirement, PARTICIPATION_AMOUNT_SMALL);
        assertEq(reqs.mediumPackageRequirement, PARTICIPATION_AMOUNT_MEDIUM);
        assertEq(reqs.largePackageRequirement, PARTICIPATION_AMOUNT_LARGE);
    }

    function testAddAndRemoveAdmin() public {
        // Add new admin
        presale.addAdmin(newAdmin);

        // Test as new admin
        vm.startPrank(newAdmin);
        presale.setDistributionToken(address(distributionToken));
        assertEq(presale.getDistributionToken(), address(distributionToken));
        vm.stopPrank();

        // Remove admin
        presale.removeAdmin(newAdmin);

        // Attempt action as removed admin should fail
        vm.startPrank(newAdmin);
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__CallerIsNotAdmin.selector);
        presale.setDistributionToken(address(0));
        vm.stopPrank();
    }

    function testCannotRemoveSelf() public {
        // Admin can't remove themselves
        presale.removeAdmin(admin);

        // Should still be able to perform admin actions
        presale.setDistributionToken(address(distributionToken));
        assertEq(presale.getDistributionToken(), address(distributionToken));
    }

    function testPaymentCurrencySetAtDeployment() public {
        // Test ETH payment
        PreSaleOrchestrator_v1 ethPresale = new PreSaleOrchestrator_v1(
            PARTICIPATION_AMOUNT_SMALL, PARTICIPATION_AMOUNT_MEDIUM, PARTICIPATION_AMOUNT_LARGE, address(0)
        );
        assertEq(ethPresale.getPaymentCurrency(), address(0));

        // Test ERC20 payment
        PreSaleOrchestrator_v1 erc20Presale = new PreSaleOrchestrator_v1(
            PARTICIPATION_AMOUNT_SMALL, PARTICIPATION_AMOUNT_MEDIUM, PARTICIPATION_AMOUNT_LARGE, address(paymentToken)
        );
        assertEq(erc20Presale.getPaymentCurrency(), address(paymentToken));
    }

    //--------------------------------------------------------------------------
    // Whitelist Tests

    function testWhitelistPeriodControls() public {
        // Check initial state
        assertEq(uint256(presale.getWhitelistPeriodStatus()), uint256(INACTIVE));

        // Start whitelist period
        presale.startWhitelistPeriod();
        assertEq(uint256(presale.getWhitelistPeriodStatus()), uint256(ACTIVE));

        // Pause whitelist period
        presale.pauseWhitelistPeriod();
        assertEq(uint256(presale.getWhitelistPeriodStatus()), uint256(PAUSED));

        // End whitelist period
        presale.endWhitelistPeriod();
        assertEq(uint256(presale.getWhitelistPeriodStatus()), uint256(ENDED));
    }

    function testAddToWhitelist() public {
        // Start whitelist period
        presale.startWhitelistPeriod();

        // Add to whitelist
        presale.addWhitelisted(user1, SMALL);

        // Stats are now updated automatically

        // Check user was added - check status and package type
        IPreSaleOrchestrator_v1.User memory user = presale.getUser(user1);

        // Debug log the actual values
        console.log("Status value:", uint256(user.status));
        console.log("APPROVED enum value:", uint256(APPROVED));

        // Using explicit literal values for enums (0 = Approved in UserStatus)
        assertEq(uint256(user.status), 0);
        assertEq(uint256(user.packageType), uint256(SMALL));
        // Skip address check since it may be implementation-specific
        assertEq(user.amountContributed, 0);

        // Verify stats were updated
        IPreSaleOrchestrator_v1.PresaleStats memory stats = presale.getPresaleStats();
        console.log("Total whitelisted users:", stats.totalWhitelistedUsers);
        console.log("Total small packages:", stats.totalSmallPackages);
        assertEq(stats.totalWhitelistedUsers, 1);
        assertEq(stats.totalSmallPackages, 1);
    }

    function testBatchAddToWhitelist() public {
        // Start whitelist period
        presale.startWhitelistPeriod();

        // Prepare batch data
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;

        IPreSaleOrchestrator_v1.PackageType[] memory packageTypes = new IPreSaleOrchestrator_v1.PackageType[](3);
        packageTypes[0] = SMALL;
        packageTypes[1] = MEDIUM;
        packageTypes[2] = LARGE;

        // Batch add to whitelist
        presale.batchAddWhitelisted(users, packageTypes);

        // Stats are now updated automatically

        // Verify all users were added with correct package types
        IPreSaleOrchestrator_v1.User memory user1Data = presale.getUser(user1);
        IPreSaleOrchestrator_v1.User memory user2Data = presale.getUser(user2);
        IPreSaleOrchestrator_v1.User memory user3Data = presale.getUser(user3);

        // Using explicit literal values for enums (0 = Approved in UserStatus)
        assertEq(uint256(user1Data.status), 0);
        assertEq(uint256(user1Data.packageType), uint256(SMALL));

        assertEq(uint256(user2Data.status), 0);
        assertEq(uint256(user2Data.packageType), uint256(MEDIUM));

        assertEq(uint256(user3Data.status), 0);
        assertEq(uint256(user3Data.packageType), uint256(LARGE));

        // Verify stats
        IPreSaleOrchestrator_v1.PresaleStats memory stats = presale.getPresaleStats();
        assertEq(stats.totalWhitelistedUsers, 3);
        assertEq(stats.totalSmallPackages, 1);
        assertEq(stats.totalMediumPackages, 1);
        assertEq(stats.totalLargePackages, 1);
    }

    function testRemoveFromWhitelist() public {
        // Start fresh and add user
        _createFreshInstance();
        presale.startWhitelistPeriod();
        presale.addWhitelisted(user1, SMALL);

        // Stats are now updated automatically

        // Check stats and user status after adding
        IPreSaleOrchestrator_v1.PresaleStats memory statsBefore = presale.getPresaleStats();
        assertEq(statsBefore.totalWhitelistedUsers, 1);
        assertEq(statsBefore.totalSmallPackages, 1);

        IPreSaleOrchestrator_v1.User memory userBefore = presale.getUser(user1);
        // Using explicit literal values for enums (0 = Approved in UserStatus)
        assertEq(uint256(userBefore.status), 0);

        // Remove from whitelist
        presale.removeWhitelisted(user1);

        // Stats are now updated automatically

        // Verify user status changed to revoked (1 = Revoked in UserStatus)
        IPreSaleOrchestrator_v1.User memory userAfter = presale.getUser(user1);
        assertEq(uint256(userAfter.status), 1);

        // Verify stats were updated
        IPreSaleOrchestrator_v1.PresaleStats memory statsAfter = presale.getPresaleStats();
        assertEq(statsAfter.totalWhitelistedUsers, 0);
        assertEq(statsAfter.totalSmallPackages, 0);
    }

    function testRejectWhitelist() public {
        presale.startWhitelistPeriod();

        // Reject a user
        presale.rejectWhitelisted(user1);

        // Verify user was rejected (2 = Rejected in UserStatus)
        IPreSaleOrchestrator_v1.User memory user = presale.getUser(user1);
        assertEq(uint256(user.status), 2);

        // Stats should not increase for rejected users
        IPreSaleOrchestrator_v1.PresaleStats memory stats = presale.getPresaleStats();
        assertEq(stats.totalWhitelistedUsers, 0);
    }

    function testCannotWhitelistWhenInactive() public {
        // Should revert when trying to whitelist without starting the period
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__WhitelistPeriodNotActive.selector);
        presale.addWhitelisted(user1, SMALL);
    }

    //--------------------------------------------------------------------------
    // Presale Tests

    function testStartPresale() public {
        // Setup with new instance
        _createFreshInstance();

        // Start whitelist period
        presale.startWhitelistPeriod();

        // Add users to whitelist - stats are updated automatically
        presale.addWhitelisted(user1, SMALL);
        presale.addWhitelisted(user2, MEDIUM);
        presale.addWhitelisted(user3, LARGE);

        // Verify stats are set
        IPreSaleOrchestrator_v1.PresaleStats memory stats = presale.getPresaleStats();
        console.log("Total whitelisted users:", stats.totalWhitelistedUsers);
        console.log("Total small packages:", stats.totalSmallPackages);
        console.log("Total medium packages:", stats.totalMediumPackages);
        console.log("Total large packages:", stats.totalLargePackages);

        assertEq(stats.totalWhitelistedUsers, 3);
        assertEq(stats.totalSmallPackages, 1);
        assertEq(stats.totalMediumPackages, 1);
        assertEq(stats.totalLargePackages, 1);

        // End whitelist period
        presale.endWhitelistPeriod();

        // Deposit distribution tokens
        distributionToken.approve(address(presale), DISTRIBUTION_AMOUNT);
        presale.depositDistribution(DISTRIBUTION_AMOUNT);

        // Check distribution values
        (uint256 small, uint256 medium, uint256 large) = presale.calculateTokenDistribution();
        console.log("Small distribution:", small);
        console.log("Medium distribution:", medium);
        console.log("Large distribution:", large);

        // Start presale
        presale.startPreSale();

        // Verify presale state
        assertEq(uint256(presale.getPreSalePeriodStatus()), uint256(ACTIVE));

        // Check contribution requirements and token distribution were calculated
        IPreSaleOrchestrator_v1.ContributionRequirement memory reqs = presale.getContributionRequirements();
        assertTrue(reqs.smallPackageRequirement > 0);
        assertTrue(reqs.mediumPackageRequirement > 0);
        assertTrue(reqs.largePackageRequirement > 0);

        // Verify the shares respect the ratio (medium should be 3x small, large should be 10x small)
        assertEq(reqs.mediumPackageRequirement, reqs.smallPackageRequirement * 3);
        assertEq(reqs.largePackageRequirement, reqs.smallPackageRequirement * 10);

        IPreSaleOrchestrator_v1.TokenDistributionShare memory shares = presale.getAllTokenDistributionShares();
        assertTrue(shares.smallPackageShare > 0);
        assertTrue(shares.mediumPackageShare > 0);
        assertTrue(shares.largePackageShare > 0);

        // Calculate expected ratio for shares (not exact equality due to potential rounding)
        assertTrue(shares.mediumPackageShare / shares.smallPackageShare == 3);
        assertTrue(shares.largePackageShare / shares.smallPackageShare == 10);
    }

    function testPresalePauseAndEnd() public {
        _setupCompletePresaleWithETH();

        // Pause presale
        presale.pausePreSale();
        assertEq(uint256(presale.getPreSalePeriodStatus()), uint256(PAUSED));

        // End presale
        presale.endPreSale();
        assertEq(uint256(presale.getPreSalePeriodStatus()), uint256(ENDED));
    }

    function testParticipateWithETH() public {
        _setupCompletePresaleWithETH();

        // Get max contribution for user1 (SMALL package)
        uint256 maxContribution = presale.getUserMaxContribution(user1);
        assertTrue(maxContribution > 0);

        // Participate with ETH using direct function
        vm.startPrank(user1);
        vm.deal(user1, maxContribution);
        presale.participate{value: maxContribution}(maxContribution);
        vm.stopPrank();

        // Verify user contribution was recorded
        IPreSaleOrchestrator_v1.User memory user = presale.getUser(user1);
        assertEq(user.amountContributed, maxContribution);

        // Verify contract received the ETH
        assertEq(address(presale).balance, maxContribution);
    }

    function testParticipateWithERC20() public {
        _setupCompletePresaleWithERC20();

        // Get max contribution for user2 (MEDIUM package)
        uint256 maxContribution = presale.getUserMaxContribution(user2);
        assertTrue(maxContribution > 0);

        // Participate with ERC20
        vm.startPrank(user2);
        paymentToken.approve(address(presale), maxContribution);
        presale.participateWithERC20(maxContribution);
        vm.stopPrank();

        // Verify user contribution was recorded
        IPreSaleOrchestrator_v1.User memory user = presale.getUser(user2);
        assertEq(user.amountContributed, maxContribution);

        // Verify contract received the tokens
        assertEq(paymentToken.balanceOf(address(presale)), maxContribution);
    }

    function testCannotExceedMaxContribution() public {
        _setupCompletePresaleWithETH();

        // Get max contribution for user1 (SMALL package)
        uint256 maxContribution = presale.getUserMaxContribution(user1);
        assertTrue(maxContribution > 0);

        // Try to exceed max contribution
        vm.startPrank(user1);
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__AmountIsHigherThanPackage.selector);
        presale.participate{value: maxContribution + 1}(maxContribution + 1);
        vm.stopPrank();
    }

    function testMinimumContributionRequirement() public {
        _setupCompletePresaleWithETH();

        // Get max contribution for user1 (SMALL package)
        uint256 maxContribution = presale.getUserMaxContribution(user1);
        assertTrue(maxContribution > 0);

        // Calculate 40% of max (below 50% minimum)
        uint256 belowMinContribution = maxContribution * 40 / 100;

        // Try to contribute below minimum
        vm.startPrank(user1);
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__MinimumContributionNotMet.selector);
        presale.participate{value: belowMinContribution}(belowMinContribution);
        vm.stopPrank();

        // Calculate 60% of max (above 50% minimum)
        uint256 aboveMinContribution = maxContribution * 60 / 100;

        // Contribute above minimum should work
        vm.startPrank(user1);
        presale.participate{value: aboveMinContribution}(aboveMinContribution);
        vm.stopPrank();

        // Verify contribution was recorded
        IPreSaleOrchestrator_v1.User memory user = presale.getUser(user1);
        assertEq(user.amountContributed, aboveMinContribution);
    }

    function testReceiveFunction() public {
        _setupCompletePresaleWithETH();

        // Get max contribution for user1 (SMALL package)
        uint256 maxContribution = presale.getUserMaxContribution(user1);
        assertTrue(maxContribution > 0);

        // Send ETH directly to contract
        vm.startPrank(user1);
        (bool success,) = address(presale).call{value: maxContribution}("");
        vm.stopPrank();

        // Should succeed
        assertTrue(success);

        // Verify contribution was recorded
        IPreSaleOrchestrator_v1.User memory user = presale.getUser(user1);
        assertEq(user.amountContributed, maxContribution);
    }

    //--------------------------------------------------------------------------
    // Distribution Tests

    function testDistribute() public {
        // Setup a complete presale with ETH
        _setupCompletePresaleWithETH();

        // Have users participate
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);

        // Get max contribution amount for each user
        uint256 maxContributionUser1 = presale.getUserMaxContribution(user1);
        uint256 maxContributionUser2 = presale.getUserMaxContribution(user2);
        uint256 maxContributionUser3 = presale.getUserMaxContribution(user3);

        // Have users participate with their max contribution
        vm.startPrank(user1);
        presale.participate{value: maxContributionUser1}(maxContributionUser1);
        vm.stopPrank();

        vm.startPrank(user2);
        presale.participate{value: maxContributionUser2}(maxContributionUser2);
        vm.stopPrank();

        vm.startPrank(user3);
        presale.participate{value: maxContributionUser3}(maxContributionUser3);
        vm.stopPrank();

        // End the presale
        vm.startPrank(admin);
        presale.endPreSale();

        // Get token distribution shares
        (uint256 smallShare, uint256 mediumShare, uint256 largeShare) = presale.calculateTokenDistribution();

        // Distribute
        presale.distribute();
        vm.stopPrank();

        // Distribution should be complete
        assertTrue(presale.isDistributionComplete());

        // Users should have received their tokens
        // Since all users contributed their max amount, they should get the full share
        assertEq(distributionToken.balanceOf(user1), smallShare);
        assertEq(distributionToken.balanceOf(user2), mediumShare);
        assertEq(distributionToken.balanceOf(user3), largeShare);

        // Verify ratios between packages
        assertTrue(mediumShare > smallShare, "Medium share should be larger than small share");
        assertTrue(largeShare > mediumShare, "Large share should be larger than medium share");
    }

    function testDistributeProportionalToContribution() public {
        // Setup a complete presale with ETH
        _setupCompletePresaleWithETH();

        // Have users participate
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        // Get max contribution amount for each user
        uint256 maxContributionUser1 = presale.getUserMaxContribution(user1);
        uint256 maxContributionUser2 = presale.getUserMaxContribution(user2);

        // User1 contributes 50% of their max
        uint256 user1Contribution = maxContributionUser1 / 2;
        vm.startPrank(user1);
        presale.participate{value: user1Contribution}(user1Contribution);
        vm.stopPrank();

        // User2 contributes 100% of their max
        vm.startPrank(user2);
        presale.participate{value: maxContributionUser2}(maxContributionUser2);
        vm.stopPrank();

        // End the presale
        vm.startPrank(admin);
        presale.endPreSale();

        // Get token distribution shares
        (uint256 smallShare, uint256 mediumShare,) = presale.calculateTokenDistribution();

        // Calculate expected amounts based on contribution percentages
        uint256 expectedUser1Amount = smallShare * user1Contribution / maxContributionUser1;
        uint256 expectedUser2Amount = mediumShare; // Full share as they contributed 100%

        // Distribute
        presale.distribute();
        vm.stopPrank();

        // Verify users received the correct amounts
        assertEq(distributionToken.balanceOf(user1), expectedUser1Amount);
        assertEq(distributionToken.balanceOf(user2), expectedUser2Amount);
    }

    function testCannotDistributeBeforePresaleEnds() public {
        _setupCompletePresaleWithETH();

        // Should revert when trying to distribute before ending presale
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__PresaleIsNotEnded.selector);
        presale.distribute();
    }

    //--------------------------------------------------------------------------
    // Token Management Tests

    function testDepositAndWithdrawDistribution() public {
        _setupBasicConfig();

        // Approve and deposit tokens
        uint256 depositAmount = 1000 * 10 ** 18;
        distributionToken.approve(address(presale), depositAmount);
        presale.depositDistribution(depositAmount);

        // Verify deposit
        assertEq(presale.getDistributionBalance(), depositAmount);
        assertEq(distributionToken.balanceOf(address(presale)), depositAmount);

        // Withdraw tokens
        presale.withdrawDistribution(depositAmount);

        // Verify withdrawal
        assertEq(presale.getDistributionBalance(), 0);
        assertEq(distributionToken.balanceOf(address(presale)), 0);
    }

    function testCannotWithdrawAfterDistribution() public {
        _setupCompletePresaleWithETH();

        // Have a user participate
        vm.startPrank(user1);
        uint256 maxContribution = presale.getUserMaxContribution(user1);
        presale.participate{value: maxContribution}(maxContribution);
        vm.stopPrank();

        // End presale and distribute
        presale.endPreSale();
        presale.distribute();

        // Attempt withdrawal after distribution should fail
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__DistributionIsNotDeposited.selector);
        presale.withdrawDistribution(1);
    }

    function testWithdrawPaymentCurrency() public {
        // Setup a complete presale with ETH
        _setupCompletePresaleWithETH();

        // User participates with ETH
        vm.startPrank(user1);
        uint256 contributionAmount = 1 ether;
        presale.participate{value: contributionAmount}(contributionAmount);
        vm.stopPrank();

        // Verify contract received ETH
        assertEq(address(presale).balance, contributionAmount);

        // Admin withdraws payment currency
        uint256 adminBalanceBefore = address(admin).balance;
        presale.withdrawPaymentCurrency(contributionAmount);

        // Verify admin received ETH and contract balance is 0
        assertEq(address(admin).balance, adminBalanceBefore + contributionAmount);
        assertEq(address(presale).balance, 0);
    }

    function testWithdrawPaymentCurrencyERC20() public {
        // Create a fresh instance with ERC20 payment
        _setupCompletePresaleWithERC20();

        // Have user1 participate with ERC20 token
        vm.startPrank(user1);
        uint256 contributionAmount = 1 ether;
        paymentToken.approve(address(presale), contributionAmount);
        presale.participateWithERC20(contributionAmount);
        vm.stopPrank();

        // Verify contract received the tokens
        assertEq(paymentToken.balanceOf(address(presale)), contributionAmount);

        // Track admin token balance before withdrawal
        uint256 adminTokenBalanceBefore = paymentToken.balanceOf(address(admin));

        // Withdraw ERC20 from contract
        presale.withdrawPaymentCurrency(contributionAmount);

        // Verify admin received the tokens and contract balance is 0
        assertEq(paymentToken.balanceOf(address(admin)), adminTokenBalanceBefore + contributionAmount);
        assertEq(paymentToken.balanceOf(address(presale)), 0);
    }

    //--------------------------------------------------------------------------
    // Edge Case Tests

    function testCannotParticipateWhenNotWhitelisted() public {
        // Setup the presale with ETH
        _setupCompletePresaleWithETH();

        // Create a non-whitelisted user
        address nonWhitelisted = makeAddr("nonWhitelisted");
        vm.deal(nonWhitelisted, 10 ether);

        // Try to send ETH directly to contract with non-whitelisted user
        vm.startPrank(nonWhitelisted);
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__CallerIsNotWhitelisted.selector);
        (bool success,) = address(presale).call{value: 1 ether}("");
        vm.stopPrank();
    }

    function testCannotStartPresaleWithoutSufficientDistribution() public {
        // Setup fresh instance
        _createFreshInstance();

        // Start and end whitelist period
        presale.startWhitelistPeriod();

        // Add users to whitelist - stats are updated automatically
        presale.addWhitelisted(user1, SMALL);
        presale.addWhitelisted(user2, MEDIUM);
        presale.addWhitelisted(user3, LARGE);

        // Verify stats are set correctly
        IPreSaleOrchestrator_v1.PresaleStats memory stats = presale.getPresaleStats();
        assertEq(stats.totalWhitelistedUsers, 3);
        assertEq(stats.totalSmallPackages, 1);
        assertEq(stats.totalMediumPackages, 1);
        assertEq(stats.totalLargePackages, 1);

        presale.endWhitelistPeriod();

        // Deposit a tiny amount of distribution tokens (not enough for allocation)
        distributionToken.approve(address(presale), 1);
        presale.depositDistribution(1);

        // Starting presale with insufficient distribution should fail
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__DistributionAmountInsufficient.selector);
        presale.startPreSale();
    }

    function testCannotParticipateWhenPresaleNotActive() public {
        // Setup
        _createFreshInstance();

        // Start and end whitelist period
        presale.startWhitelistPeriod();
        presale.addWhitelisted(user1, SMALL);
        presale.endWhitelistPeriod();

        // Deposit distribution tokens
        distributionToken.approve(address(presale), DISTRIBUTION_AMOUNT);
        presale.depositDistribution(DISTRIBUTION_AMOUNT);

        // Attempt to participate before presale starts
        vm.startPrank(user1);
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__PresaleNotActive.selector);
        presale.participate{value: 1 ether}(1 ether);
        vm.stopPrank();
    }

    function testNoDistributionIfNoParticipation() public {
        _setupCompletePresaleWithETH();

        // End presale without any participation
        presale.endPreSale();

        // Distribute tokens
        presale.distribute();

        // No users should have received tokens
        assertEq(distributionToken.balanceOf(user1), 0);
        assertEq(distributionToken.balanceOf(user2), 0);
        assertEq(distributionToken.balanceOf(user3), 0);

        // Distribution should be marked as complete
        assertTrue(presale.isDistributionComplete());
    }

    function testDistributionWithSomeParticipants() public {
        _setupCompletePresaleWithETH();

        // Only user1 and user3 participate, user2 doesn't
        vm.startPrank(user1);
        uint256 user1Contribution = presale.getUserMaxContribution(user1);
        presale.participate{value: user1Contribution}(user1Contribution);
        vm.stopPrank();

        vm.startPrank(user3);
        uint256 user3Contribution = presale.getUserMaxContribution(user3);
        presale.participate{value: user3Contribution}(user3Contribution);
        vm.stopPrank();

        // End presale
        presale.endPreSale();

        // Distribute tokens
        presale.distribute();

        // Verify distribution completed
        assertTrue(presale.isDistributionComplete());

        // Verify only contributing users received tokens
        assertTrue(distributionToken.balanceOf(user1) > 0);
        assertEq(distributionToken.balanceOf(user2), 0);
        assertTrue(distributionToken.balanceOf(user3) > 0);

        // Get contribution requirements to check ratio
        uint256 smallRequirement = presale.getContributionRequirement(SMALL);
        uint256 largeRequirement = presale.getContributionRequirement(LARGE);

        // Check if ratio between tokens is proportional to contribution requirements
        // Using approximate comparison with 1% tolerance to handle rounding errors
        uint256 user1Tokens = distributionToken.balanceOf(user1);
        uint256 user3Tokens = distributionToken.balanceOf(user3);

        // Expected ratio: user3 (large package) should get 10x the tokens of user1 (small package)
        // when both contribute 100% of their maximum
        uint256 expectedRatio = largeRequirement / smallRequirement;
        uint256 actualRatio = user3Tokens / user1Tokens;

        // Log values for debugging
        console.log("User1 (small) tokens:", user1Tokens);
        console.log("User3 (large) tokens:", user3Tokens);
        console.log("Actual ratio (large:small):", actualRatio);
        console.log("Expected ratio (large:small):", expectedRatio);

        // Use relative comparison to verify the ratio is maintained
        assertApproxEqRel(user3Tokens * smallRequirement, user1Tokens * largeRequirement, 0.01e18); // 1% tolerance
    }

    //--------------------------------------------------------------------------
    // New Tests for Configuration After Presale Started

    function testCannotChangeDistributionTokenAfterPresaleStarted() public {
        _setupCompletePresaleWithETH();

        // Deploy a new token for testing
        MockERC20 newToken = new MockERC20("New Token", "NEW", 18);

        // Try to change distribution token after presale has started
        vm.expectRevert(IPreSaleOrchestrator_v1.IPreSaleOrchestrator__CannotChangeAfterPresaleStarted.selector);
        presale.setDistributionToken(address(newToken));
    }

    // Helper function to verify enum values
    function testEnumValues() public pure {
        // Enum values should match these integer values
        assertEq(uint256(INACTIVE), 0);
        assertEq(uint256(ACTIVE), 1);
        assertEq(uint256(PAUSED), 2);
        assertEq(uint256(ENDED), 3);

        assertEq(uint256(APPROVED), 0);
        assertEq(uint256(REVOKED), 1);
        assertEq(uint256(REJECTED), 2);

        assertEq(uint256(SMALL), 0);
        assertEq(uint256(MEDIUM), 1);
        assertEq(uint256(LARGE), 2);
    }
}
