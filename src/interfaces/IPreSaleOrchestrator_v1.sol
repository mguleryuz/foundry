// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IPreSaleOrchestrator_v1 {
    //--------------------------------------------------------------------------
    // Events

    // Admin

    /// @notice The minter is set.
    event AdminAdded(address indexed admin);

    /// @notice The minter is set.
    event AdminRemoved(address indexed admin);

    /// @notice Treasury address is set.
    event TreasurySet(address indexed treasury);

    /// @notice Distribution token is set.
    event DistributionTokenSet(address indexed token);

    /// @notice Whitelist period is started.
    event WhitelistPeriodStarted();

    /// @notice Whitelist period is paused.
    event WhitelistPeriodPaused();

    /// @notice Whitelist period is ended.
    event WhitelistPeriodEnded();

    // Token Balances

    /// @notice Treasury token is deposited.
    event TreasuryDeposited(uint256 amount);

    /// @notice Treasury token is withdrawn.
    event TreasuryWithdrawn(uint256 amount);

    /// @notice The distribution is deposited.
    event DistributionDeposited(uint256 amount);

    /// @notice The distribution is withdrawn.
    event DistributionWithdrawn(uint256 amount);

    // Whitelist

    /// @notice A address is added to the whitelist.
    event WhitelistedGranted(address indexed whitelisted);

    /// @notice A address is removed from the whitelist.
    event WhitelistedRevoked(address indexed whitelisted);

    /// @notice A address is rejected from the whitelist.
    event WhitelistedRejected(address indexed whitelisted);

    // Pre-sale

    /// @notice the pre-sale is started.
    event PreSaleStarted(uint256 startTime, uint256 endTime);

    /// @notice the pre-sale is ended.
    event PreSaleEnded();

    //--------------------------------------------------------------------------
    // Errors

    error IPreSaleOrchestrator__CallerIsNotAdmin();

    error IPreSaleOrchestrator__CallerIsNotWhitelisted();

    error IPreSaleOrchestrator__WhitelistPeriodNotActive();

    //--------------------------------------------------------------------------
    // Functions

    // Admin

    /// @notice Adds an admin to the pre-sale orchestrator.
    function addAdmin(address _admin) external;

    /// @notice Removes an admin from the pre-sale orchestrator.
    function removeAdmin(address _admin) external;

    /// @notice Sets the treasury address.
    function setTreasury(address _treasury) external;

    /// @notice Sets the distribution token.
    function setDistributionToken(address _token) external;

    /// @notice Starts the whitelist period.
    function startWhitelistPeriod() external;

    /// @notice Pauses the whitelist period.
    function pauseWhitelistPeriod() external;

    /// @notice Ends the whitelist period.
    function endWhitelistPeriod() external;

    // Token Balances

    /// @notice Deposits the treasury token.
    function depositTreasury(uint256 _amount) external;

    /// @notice Withdraws the treasury token.
    function withdrawTreasury(uint256 _amount) external;

    /// @notice Deposits the distribution token.
    function depositDistribution(uint256 _amount) external;

    /// @notice Withdraws the distribution token.
    function withdrawDistribution(uint256 _amount) external;

    // Whitelist

    /// @notice Adds a address to the whitelist.
    function addWhitelisted(address _whitelisted) external;

    /// @notice Removes a address from the whitelist.
    function removeWhitelisted(address _whitelisted) external;

    /// @notice Rejects a address from the whitelist.
    function rejectWhitelisted(address _whitelisted) external;

    // Pre-sale

    /// @notice Starts the pre-sale.
    function startPreSale() external;

    /// @notice Ends the pre-sale.
    function endPreSale() external;
}
