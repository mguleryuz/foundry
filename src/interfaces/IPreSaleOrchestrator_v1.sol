// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IPreSaleOrchestrator_v1 {
    //--------------------------------------------------------------------------
    // Events

    // Admin

    /// @notice A new admin is added to the contract.
    event AdminAdded(address indexed admin);

    /// @notice An admin is removed from the contract.
    event AdminRemoved(address indexed admin);

    /// @notice Payment currency is set.
    event PaymentCurrencySet(address indexed currency);

    /// @notice Distribution token is set.
    event DistributionTokenSet(address indexed token);

    /// @notice Whitelist period is started.
    event WhitelistPeriodStarted();

    /// @notice Whitelist period is paused.
    event WhitelistPeriodPaused();

    /// @notice Whitelist period is ended.
    event WhitelistPeriodEnded();

    // Token Balances

    /// @notice User deposits contribution into the presale.
    event UserParticipated(address indexed user, uint256 amount);

    /// @notice Payment currency is withdrawn.
    event PaymentCurrencyWithdrawn(uint256 amount);

    /// @notice The distribution token is deposited from address.
    event DistributionDeposited(address indexed from, uint256 amount);

    /// @notice The distribution token is withdrawn to address.
    event DistributionWithdrawn(address indexed to, uint256 amount);

    /// @notice The distribution is distributed to address.
    event DistributionDistributed(address indexed to, uint256 amount);

    /// @notice Token distribution shares were calculated.
    event TokenDistributionCalculated(uint256 smallShare, uint256 mediumShare, uint256 largeShare);

    // Whitelist

    /// @notice A address is added to the whitelist with assigned package type.
    event WhitelistedGranted(address indexed whitelisted, PackageType packageType);

    /// @notice A address is removed from the whitelist.
    event WhitelistedRevoked(address indexed whitelisted);

    /// @notice A address is rejected from the whitelist.
    event WhitelistedRejected(address indexed whitelisted);

    // Pre-sale

    /// @notice the pre-sale is started.
    event PreSaleStarted();

    /// @notice the pre-sale is paused.
    event PreSalePaused();

    /// @notice the pre-sale is ended.
    event PreSaleEnded();

    //--------------------------------------------------------------------------
    // Errors

    error IPreSaleOrchestrator__CallerIsNotAdmin();

    error IPreSaleOrchestrator__CallerIsNotWhitelisted();

    error IPreSaleOrchestrator__WhitelistPeriodNotActive();

    error IPreSaleOrchestrator__WhitelistPeriodNotEnded();

    error IPreSaleOrchestrator__PresaleAlreadyStarted();

    error IPreSaleOrchestrator__PresaleNotActive();

    error IPreSaleOrchestrator__AmountIsHigherThanPackage();

    error IPreSaleOrchestrator__DistributionTokenIsNotSet();

    error IPreSaleOrchestrator__DistributionIsNotDeposited();

    error IPreSaleOrchestrator__DistributionAmountInsufficient();

    error IPreSaleOrchestrator__PresaleIsNotEnded();

    error IPreSaleOrchestrator__PresaleHasEnded();

    error IPreSaleOrchestrator__NotDistributionToken();

    error IPreSaleOrchestrator__MinimumContributionNotMet();

    error IPreSaleOrchestrator__NoWhitelistedUsers();

    //--------------------------------------------------------------------------
    // Enums

    enum ProcessStatus {
        Inactive,
        Active,
        Paused,
        Ended
    }

    enum UserStatus {
        Approved,
        Revoked,
        Rejected
    }

    enum PackageType {
        Small,
        Medium,
        Large
    }

    //--------------------------------------------------------------------------
    // Structs

    struct PresaleConfig {
        address distributionToken;
        address paymentCurrency; // ETH if address(0), otherwise ERC20 token
        ProcessStatus whitelistStatus;
        ProcessStatus preSaleStatus;
        bool distributionComplete;
    }

    struct TokenDistributionShare {
        uint256 smallPackageShare;
        uint256 mediumPackageShare;
        uint256 largePackageShare;
    }

    struct User {
        UserStatus status;
        PackageType packageType;
        address address_;
        uint256 amountContributed;
    }

    struct PresaleStats {
        uint256 totalWhitelistedUsers;
        uint256 totalSmallPackages;
        uint256 totalMediumPackages;
        uint256 totalLargePackages;
        uint256 totalContributionsReceived;
        uint256 totalDistributionAmount;
    }

    struct ContributionRequirement {
        uint256 smallPackageRequirement;
        uint256 mediumPackageRequirement;
        uint256 largePackageRequirement;
    }

    //--------------------------------------------------------------------------
    // External Functions

    // Admin

    /// @notice Adds an admin to the pre-sale orchestrator.
    function addAdmin(address _admin) external;

    /// @notice Removes an admin from the pre-sale orchestrator.
    function removeAdmin(address _admin) external;

    /// @notice Sets the distribution token (admin only) (before presale period only).
    /// @dev Distribution token is the token being sold in the presale.
    function setDistributionToken(address _token) external;

    /// @notice Distributes the tokens to the users (admin only) (after presale period only).
    /// @dev This automatically sends tokens to all participating users based on their contributions.
    function distribute() external;

    // Token Balances

    /// @notice Allows a user to participate by sending ETH directly.
    /// @dev Only works for whitelisted users and ETH payments.
    function participate(uint256 _amount) external payable;

    /// @notice Allows a whitelisted user to participate with ERC20 tokens.
    /// @dev Only used when payment currency is an ERC20 token. User must approve first.
    function participateWithERC20(uint256 _amount) external;

    /// @notice Withdraws the collected user contributions (admin only).
    /// @dev Can only be called by admin after presale has ended.
    function withdrawPaymentCurrency(uint256 _amount) external;

    /// @notice Deposits the distribution token for later distribution (admin only).
    /// @dev This is where admin deposits tokens that will be sold/distributed.
    function depositDistribution(uint256 _amount) external;

    /// @notice Withdraws the distribution token (admin only).
    /// @dev Can only be called before distribution occurs.
    function withdrawDistribution(uint256 _amount) external;

    // Whitelist Admin

    /// @notice Starts the whitelist period (admin only).
    function startWhitelistPeriod() external;

    /// @notice Pauses the whitelist period (admin only).
    function pauseWhitelistPeriod() external;

    /// @notice Ends the whitelist period (admin only).
    function endWhitelistPeriod() external;

    // Whitelist Manager

    /// @notice Adds a address to the whitelist with an assigned package type (admin only) (during whitelist period).
    function addWhitelisted(address _whitelisted, PackageType _packageType) external;

    /// @notice Batch adds addresses to the whitelist (admin only) (during whitelist period).
    function batchAddWhitelisted(address[] calldata _whitelisted, PackageType[] calldata _packageTypes) external;

    /// @notice Removes a address from the whitelist (admin only).
    function removeWhitelisted(address _whitelisted) external;

    /// @notice Rejects a address from the whitelist (admin only).
    function rejectWhitelisted(address _whitelisted) external;

    // Pre-sale Admin

    /// @notice Starts the pre-sale (admin only) (after whitelist period has ended).
    /// @dev This will finalize token distribution shares and contribution requirements based on approved whitelist.
    /// @dev Requires distribution token to be deposited and sufficient for all whitelisted users.
    function startPreSale() external;

    /// @notice Pauses the pre-sale (admin only).
    function pausePreSale() external;

    /// @notice Ends the pre-sale (admin only).
    function endPreSale() external;

    // Getters

    /// @notice Returns the token amount a user will receive for the specified package type.
    /// @dev This is calculated when presale starts based on total distribution and whitelisted users.
    function getTokenDistributionShare(PackageType _packageType) external view returns (uint256);

    /// @notice Returns all token distribution shares.
    function getAllTokenDistributionShares() external view returns (TokenDistributionShare memory);

    /// @notice Returns the user information.
    function getUser(address _user) external view returns (User memory);

    /// @notice Returns the user's maximum contribution allowed based on package type.
    function getUserMaxContribution(address _user) external view returns (uint256);

    /// @notice Returns the presale configuration.
    function getPresaleConfig() external view returns (PresaleConfig memory);

    /// @notice Returns the distribution token.
    function getDistributionToken() external view returns (address);

    /// @notice Returns the payment currency.
    /// @dev Returns address(0) if payments are in ETH, otherwise the ERC20 token address.
    function getPaymentCurrency() external view returns (address);

    /// @notice Returns the whitelist period status.
    function getWhitelistPeriodStatus() external view returns (ProcessStatus);

    /// @notice Returns the pre-sale period status.
    function getPreSalePeriodStatus() external view returns (ProcessStatus);

    /// @notice Returns the distribution balance.
    /// @dev This is the amount of tokens available to be distributed.
    function getDistributionBalance() external view returns (uint256);

    /// @notice Returns the payment currency balance.
    /// @dev This is the total amount of user contributions collected.
    function getPaymentCurrencyBalance() external view returns (uint256);

    /// @notice Returns whether distribution has been completed.
    function isDistributionComplete() external view returns (bool);

    /// @notice Returns current presale statistics.
    function getPresaleStats() external view returns (PresaleStats memory);

    /// @notice Returns the contribution requirements for each package type.
    /// @dev Requirements are calculated based on distribution token amount and whitelisted users.
    function getContributionRequirements() external view returns (ContributionRequirement memory);

    /// @notice Returns the contribution requirement for a specific package type.
    /// @dev Requirement is calculated based on distribution token amount and whitelisted users.
    function getContributionRequirement(PackageType _packageType) external view returns (uint256);

    //--------------------------------------------------------------------------
    // Misc

    /// @notice Calculates the token distribution shares based on the distribution balance and whitelisted users.
    /// @dev This is automatically called when presale starts but can be viewed before.
    /// @dev Returns token shares for small, medium, and large packages respectively.
    function calculateTokenDistribution() external view returns (uint256, uint256, uint256);

    /// @notice Validates if the current distribution amount is sufficient for all whitelisted users.
    /// @dev Used to check if there's enough distribution token before starting presale.
    /// @return sufficient True if distribution amount is sufficient, false otherwise.
    /// @return requiredAmount The total amount required for all whitelisted users.
    function isDistributionSufficient() external view returns (bool sufficient, uint256 requiredAmount);

    /// @notice Fallback function to receive ETH payments (if payment currency is ETH).
    receive() external payable;
}
