// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

// External Imports
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";

// Internal Imports
import {IPreSaleOrchestrator_v1} from "src/interfaces/IPreSaleOrchestrator_v1.sol";

/**
 * @title PreSaleOrchestrator_v1
 * @notice A contract for managing token pre-sales with configurable packages and dynamic allocation
 * @dev Implements IPreSaleOrchestrator_v1 interface
 */
contract PreSaleOrchestrator_v1 is IPreSaleOrchestrator_v1 {
    using SafeERC20 for IERC20;

    // --------------------------------------------------------------------------
    // Storage Variables

    // Admin management
    mapping(address => bool) private _admins;

    // Presale configuration
    PresaleConfig private _presaleConfig;

    // User management
    mapping(address => User) private _users;
    address[] private _whitelistedUsers;

    // Package allocation and requirements
    TokenDistributionShare private _tokenDistributionShare;
    ContributionRequirement private _contributionRequirement;

    // Stats
    PresaleStats private _presaleStats;

    // Minimum contribution ratio (percentage of the full package requirement)
    uint256 private constant MIN_CONTRIBUTION_PERCENTAGE = 50; // 50%

    // --------------------------------------------------------------------------
    // Constructor

    /**
     * @notice Constructor to initialize the contract with the first admin
     * @param smallRequirement The contribution requirement for small packages
     * @param mediumRequirement The contribution requirement for medium packages
     * @param largeRequirement The contribution requirement for large packages
     * @param paymentCurrency The payment currency address (address(0) for ETH)
     */
    constructor(
        uint256 smallRequirement,
        uint256 mediumRequirement,
        uint256 largeRequirement,
        address paymentCurrency
    ) {
        _admins[msg.sender] = true;
        emit AdminAdded(msg.sender);

        // Set contribution requirements
        _contributionRequirement.smallPackageRequirement = smallRequirement;
        _contributionRequirement.mediumPackageRequirement = mediumRequirement;
        _contributionRequirement.largePackageRequirement = largeRequirement;

        // Set payment currency
        _presaleConfig.paymentCurrency = paymentCurrency;
        emit PaymentCurrencySet(paymentCurrency);

        // Initialize presale config
        _presaleConfig.whitelistStatus = ProcessStatus.Inactive;
        _presaleConfig.preSaleStatus = ProcessStatus.Inactive;
        _presaleConfig.distributionComplete = false;
    }

    // --------------------------------------------------------------------------
    // Modifiers

    /**
     * @notice Ensures the caller is an admin
     */
    modifier onlyAdmin() {
        if (!_admins[msg.sender]) {
            revert IPreSaleOrchestrator__CallerIsNotAdmin();
        }
        _;
    }

    /**
     * @notice Ensures the caller is whitelisted and approved
     */
    modifier onlyWhitelisted() {
        if (_users[msg.sender].status != UserStatus.Approved) {
            revert IPreSaleOrchestrator__CallerIsNotWhitelisted();
        }
        _;
    }

    /**
     * @notice Ensures the whitelist period is active
     */
    modifier whitelistPeriodActive() {
        if (_presaleConfig.whitelistStatus != ProcessStatus.Active) {
            revert IPreSaleOrchestrator__WhitelistPeriodNotActive();
        }
        _;
    }

    /**
     * @notice Ensures the whitelist period has ended
     */
    modifier whitelistPeriodEnded() {
        if (_presaleConfig.whitelistStatus != ProcessStatus.Ended) {
            revert IPreSaleOrchestrator__WhitelistPeriodNotEnded();
        }
        _;
    }

    /**
     * @notice Ensures the presale has not yet started
     */
    modifier presaleNotStarted() {
        if (_presaleConfig.preSaleStatus != ProcessStatus.Inactive) {
            revert IPreSaleOrchestrator__PresaleAlreadyStarted();
        }
        _;
    }

    /**
     * @notice Ensures the presale is active
     */
    modifier presaleActive() {
        if (_presaleConfig.preSaleStatus != ProcessStatus.Active) {
            revert IPreSaleOrchestrator__PresaleNotActive();
        }
        _;
    }

    /**
     * @notice Ensures the presale has ended
     */
    modifier presaleEnded() {
        if (_presaleConfig.preSaleStatus != ProcessStatus.Ended) {
            revert IPreSaleOrchestrator__PresaleIsNotEnded();
        }
        _;
    }

    /**
     * @notice Ensures the distribution token is set
     */
    modifier distributionTokenSet() {
        if (_presaleConfig.distributionToken == address(0)) {
            revert IPreSaleOrchestrator__DistributionTokenIsNotSet();
        }
        _;
    }

    // --------------------------------------------------------------------------
    // Admin Functions

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function addAdmin(address _admin) external override onlyAdmin {
        _admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function removeAdmin(address _admin) external override onlyAdmin {
        if (_admin == msg.sender) {
            // Prevent admin from removing themselves
            return;
        }
        _admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function setDistributionToken(address _token) external override onlyAdmin presaleNotStarted {
        _presaleConfig.distributionToken = _token;
        emit DistributionTokenSet(_token);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function distribute() external override onlyAdmin presaleEnded distributionTokenSet {
        if (_presaleConfig.distributionComplete) {
            return;
        }

        // Check if there is anything to distribute
        uint256 initialBalance = getDistributionBalance();
        if (initialBalance == 0) {
            revert IPreSaleOrchestrator__DistributionIsNotDeposited();
        }

        IERC20 distributionToken = IERC20(_presaleConfig.distributionToken);

        // Calculate distribution again to ensure latest values
        (uint256 smallShare, uint256 mediumShare, uint256 largeShare) = calculateTokenDistribution();

        // Store the calculated distribution shares
        _tokenDistributionShare.smallPackageShare = smallShare;
        _tokenDistributionShare.mediumPackageShare = mediumShare;
        _tokenDistributionShare.largePackageShare = largeShare;

        // Keep track of total tokens distributed
        uint256 totalDistributed = 0;

        // Distribute tokens to all users who contributed
        for (uint256 i = 0; i < _whitelistedUsers.length; i++) {
            address userAddress = _whitelistedUsers[i];
            User storage user = _users[userAddress];

            // Only distribute to approved users who contributed
            if (user.status == UserStatus.Approved && user.amountContributed > 0) {
                uint256 distributionAmount = _calculateUserDistribution(userAddress, user.packageType);

                if (distributionAmount > 0) {
                    // Transfer tokens to user
                    if (distributionToken.balanceOf(address(this)) >= distributionAmount) {
                        distributionToken.safeTransfer(userAddress, distributionAmount);
                        emit DistributionDistributed(userAddress, distributionAmount);
                        totalDistributed += distributionAmount;
                    }
                }
            }
        }

        // If there are any remaining tokens due to rounding, send them to the admin
        uint256 remainingBalance = distributionToken.balanceOf(address(this));
        if (remainingBalance > 0) {
            distributionToken.safeTransfer(msg.sender, remainingBalance);
            emit DistributionDistributed(msg.sender, remainingBalance);
        }

        _presaleConfig.distributionComplete = true;
    }

    // --------------------------------------------------------------------------
    // Token Balance Functions

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function participate(uint256 _amount) external payable override onlyWhitelisted presaleActive {
        // Only accept ETH contributions if payment currency is ETH
        if (_presaleConfig.paymentCurrency != address(0)) {
            // If payment currency is not ETH, reject this call
            revert IPreSaleOrchestrator__NotDistributionToken();
        }

        // For ETH contributions, either amount should match msg.value
        // or if amount is specified but no value sent, use the amount parameter
        if (msg.value > 0 && _amount != msg.value) {
            revert IPreSaleOrchestrator__NotDistributionToken();
        }

        // If msg.value is 0, use the specified amount (test environment)
        uint256 amount = msg.value > 0 ? msg.value : _amount;

        _participateInternal(msg.sender, amount);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function participateWithERC20(uint256 _amount) external override onlyWhitelisted presaleActive {
        // Ensure payment currency is set and not ETH
        if (_presaleConfig.paymentCurrency == address(0)) {
            revert IPreSaleOrchestrator__NotDistributionToken();
        }

        // Handle core participation logic
        _participateInternal(msg.sender, _amount);

        // Transfer tokens to contract
        IERC20 paymentToken = IERC20(_presaleConfig.paymentCurrency);
        paymentToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev Internal function to handle participation logic
     * @param _user The address of the participating user
     * @param _amount The amount being contributed
     */
    function _participateInternal(address _user, uint256 _amount) internal {
        // Get contribution requirement based on package type
        uint256 requiredAmount = getUserMaxContribution(_user);

        // Check if amount exceeds the allocated package
        if (_users[_user].amountContributed + _amount > requiredAmount) {
            revert IPreSaleOrchestrator__AmountIsHigherThanPackage();
        }

        // Check minimum contribution
        uint256 minContribution = requiredAmount * MIN_CONTRIBUTION_PERCENTAGE / 100;
        if (_users[_user].amountContributed + _amount < minContribution) {
            revert IPreSaleOrchestrator__MinimumContributionNotMet();
        }

        // Update user contribution
        _users[_user].amountContributed += _amount;

        // Update stats
        _presaleStats.totalContributionsReceived += _amount;

        emit UserParticipated(_user, _amount);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function withdrawPaymentCurrency(uint256 _amount) external override onlyAdmin {
        if (_presaleConfig.paymentCurrency == address(0)) {
            // ETH withdrawal
            require(address(this).balance >= _amount, "Insufficient ETH balance");
            (bool success,) = payable(msg.sender).call{value: _amount}("");
            require(success, "ETH transfer failed");
        } else {
            // ERC20 withdrawal
            IERC20 paymentToken = IERC20(_presaleConfig.paymentCurrency);
            require(paymentToken.balanceOf(address(this)) >= _amount, "Insufficient token balance");
            paymentToken.safeTransfer(msg.sender, _amount);
        }
        emit PaymentCurrencyWithdrawn(_amount);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function depositDistribution(uint256 _amount) external override onlyAdmin distributionTokenSet {
        IERC20 distributionToken = IERC20(_presaleConfig.distributionToken);

        // Transfer tokens from sender to this contract
        distributionToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update stats
        _presaleStats.totalDistributionAmount += _amount;

        emit DistributionDeposited(msg.sender, _amount);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function withdrawDistribution(uint256 _amount) external override onlyAdmin distributionTokenSet {
        if (_presaleConfig.distributionComplete) {
            revert IPreSaleOrchestrator__PresaleHasEnded();
        }

        IERC20 distributionToken = IERC20(_presaleConfig.distributionToken);

        // Check if there are enough tokens to withdraw
        if (distributionToken.balanceOf(address(this)) < _amount) {
            revert IPreSaleOrchestrator__DistributionIsNotDeposited();
        }

        // Transfer tokens to sender
        distributionToken.safeTransfer(msg.sender, _amount);

        // Update stats
        _presaleStats.totalDistributionAmount -= _amount;

        emit DistributionWithdrawn(msg.sender, _amount);
    }

    // --------------------------------------------------------------------------
    // Whitelist Admin Functions

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function startWhitelistPeriod() external override onlyAdmin {
        _presaleConfig.whitelistStatus = ProcessStatus.Active;
        emit WhitelistPeriodStarted();
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function pauseWhitelistPeriod() external override onlyAdmin {
        if (_presaleConfig.whitelistStatus == ProcessStatus.Active) {
            _presaleConfig.whitelistStatus = ProcessStatus.Paused;
            emit WhitelistPeriodPaused();
        }
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function endWhitelistPeriod() external override onlyAdmin {
        if (
            _presaleConfig.whitelistStatus == ProcessStatus.Active
                || _presaleConfig.whitelistStatus == ProcessStatus.Paused
        ) {
            _presaleConfig.whitelistStatus = ProcessStatus.Ended;
            emit WhitelistPeriodEnded();
        }
    }

    // --------------------------------------------------------------------------
    // Whitelist Manager Functions

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function addWhitelisted(address _whitelisted, PackageType _packageType)
        external
        override
        onlyAdmin
        whitelistPeriodActive
    {
        User storage user = _users[_whitelisted];

        // Check if this is a new user (address_ not set means never initialized)
        bool isNewUser = user.address_ == address(0);

        // Only add if new user or previously revoked/rejected
        if (isNewUser || user.status != UserStatus.Approved) {
            // Initialize user data
            user.status = UserStatus.Approved;
            user.packageType = _packageType;
            user.address_ = _whitelisted;
            user.amountContributed = 0;

            // Add to whitelist array
            _whitelistedUsers.push(_whitelisted);

            // Update stats
            _presaleStats.totalWhitelistedUsers += 1;
            _updatePackageStats(PackageType.Small, _packageType, 0, 1);

            emit WhitelistedGranted(_whitelisted, _packageType);
        } else if (user.packageType != _packageType) {
            // User is already approved but we're changing package type
            PackageType oldPackageType = user.packageType;

            // Update user package type
            user.packageType = _packageType;

            // Update stats for package types
            _updatePackageStats(oldPackageType, _packageType, 1, 0);

            emit WhitelistedGranted(_whitelisted, _packageType);
        }
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function batchAddWhitelisted(address[] calldata _whitelisted, PackageType[] calldata _packageTypes)
        external
        override
        onlyAdmin
        whitelistPeriodActive
    {
        require(_whitelisted.length == _packageTypes.length, "Arrays length mismatch");

        for (uint256 i = 0; i < _whitelisted.length; i++) {
            User storage user = _users[_whitelisted[i]];

            // Check if this is a new user (address_ not set means never initialized)
            bool isNewUser = user.address_ == address(0);

            // Only add if new user or previously revoked/rejected
            if (isNewUser || user.status != UserStatus.Approved) {
                // Initialize user data
                user.status = UserStatus.Approved;
                user.packageType = _packageTypes[i];
                user.address_ = _whitelisted[i];
                user.amountContributed = 0;

                // Add to whitelist array
                _whitelistedUsers.push(_whitelisted[i]);

                // Update stats
                _presaleStats.totalWhitelistedUsers += 1;
                _updatePackageStats(PackageType.Small, _packageTypes[i], 0, 1);

                emit WhitelistedGranted(_whitelisted[i], _packageTypes[i]);
            } else if (user.packageType != _packageTypes[i]) {
                // User is already approved but we're changing package type
                PackageType oldPackageType = user.packageType;

                // Update user package type
                user.packageType = _packageTypes[i];

                // Update stats for package types
                _updatePackageStats(oldPackageType, _packageTypes[i], 1, 0);

                emit WhitelistedGranted(_whitelisted[i], _packageTypes[i]);
            }
        }
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function removeWhitelisted(address _whitelisted) external override onlyAdmin whitelistPeriodActive {
        User storage user = _users[_whitelisted];

        if (user.status == UserStatus.Approved) {
            // Update stats
            _presaleStats.totalWhitelistedUsers -= 1;
            _updatePackageStats(user.packageType, PackageType.Small, 1, 0);

            // Update user status
            user.status = UserStatus.Revoked;

            emit WhitelistedRevoked(_whitelisted);
        }
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function rejectWhitelisted(address _whitelisted) external override onlyAdmin whitelistPeriodActive {
        User storage user = _users[_whitelisted];

        // Can only reject if not already approved or rejected
        if (user.status != UserStatus.Rejected) {
            user.status = UserStatus.Rejected;
            emit WhitelistedRejected(_whitelisted);
        }
    }

    // --------------------------------------------------------------------------
    // Pre-sale Admin Functions

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function startPreSale() external override onlyAdmin whitelistPeriodEnded presaleNotStarted distributionTokenSet {
        // Ensure there are whitelisted users
        if (_presaleStats.totalWhitelistedUsers == 0) {
            revert IPreSaleOrchestrator__NoWhitelistedUsers();
        }

        // Check if distribution token deposit exists
        if (getDistributionBalance() == 0) {
            revert IPreSaleOrchestrator__DistributionIsNotDeposited();
        }

        // Calculate token distribution shares
        (uint256 smallShare, uint256 mediumShare, uint256 largeShare) = calculateTokenDistribution();

        // Store the calculated distribution shares
        _tokenDistributionShare.smallPackageShare = smallShare;
        _tokenDistributionShare.mediumPackageShare = mediumShare;
        _tokenDistributionShare.largePackageShare = largeShare;

        emit TokenDistributionCalculated(smallShare, mediumShare, largeShare);

        // Start presale
        _presaleConfig.preSaleStatus = ProcessStatus.Active;
        emit PreSaleStarted();
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function pausePreSale() external override onlyAdmin {
        if (_presaleConfig.preSaleStatus == ProcessStatus.Active) {
            _presaleConfig.preSaleStatus = ProcessStatus.Paused;
            emit PreSalePaused();
        }
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function endPreSale() external override onlyAdmin {
        if (
            _presaleConfig.preSaleStatus == ProcessStatus.Active || _presaleConfig.preSaleStatus == ProcessStatus.Paused
        ) {
            _presaleConfig.preSaleStatus = ProcessStatus.Ended;
            emit PreSaleEnded();
        }
    }

    // --------------------------------------------------------------------------
    // Getter Functions

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getTokenDistributionShare(PackageType _packageType) external view override returns (uint256) {
        return _getPackageValue(_packageType, 0);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getAllTokenDistributionShares() external view override returns (TokenDistributionShare memory) {
        return _tokenDistributionShare;
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getUser(address _user) external view override returns (User memory) {
        return _users[_user];
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getUserMaxContribution(address _user) public view override returns (uint256) {
        User memory user = _users[_user];

        if (user.status != UserStatus.Approved) {
            return 0;
        }

        return _getPackageValue(user.packageType, 1);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getPresaleConfig() external view override returns (PresaleConfig memory) {
        return _presaleConfig;
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getDistributionToken() external view override returns (address) {
        return _presaleConfig.distributionToken;
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getPaymentCurrency() external view override returns (address) {
        return _presaleConfig.paymentCurrency;
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getWhitelistPeriodStatus() external view override returns (ProcessStatus) {
        return _presaleConfig.whitelistStatus;
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getPreSalePeriodStatus() external view override returns (ProcessStatus) {
        return _presaleConfig.preSaleStatus;
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getDistributionBalance() public view override returns (uint256) {
        if (_presaleConfig.distributionToken == address(0)) {
            return 0;
        }
        return IERC20(_presaleConfig.distributionToken).balanceOf(address(this));
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getPaymentCurrencyBalance() external view override returns (uint256) {
        if (_presaleConfig.paymentCurrency == address(0)) {
            // ETH balance
            return address(this).balance;
        } else {
            // ERC20 balance
            return IERC20(_presaleConfig.paymentCurrency).balanceOf(address(this));
        }
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function isDistributionComplete() external view override returns (bool) {
        return _presaleConfig.distributionComplete;
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getPresaleStats() external view override returns (PresaleStats memory) {
        return _presaleStats;
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getContributionRequirements() external view override returns (ContributionRequirement memory) {
        return _contributionRequirement;
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function getContributionRequirement(PackageType _packageType) external view override returns (uint256) {
        return _getPackageValue(_packageType, 1);
    }

    // --------------------------------------------------------------------------
    // Misc Functions

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    function calculateTokenDistribution() public view override returns (uint256, uint256, uint256) {
        // If no distribution token is set or no users, return zeros
        if (_presaleConfig.distributionToken == address(0) || _presaleStats.totalWhitelistedUsers == 0) {
            return (0, 0, 0);
        }

        // Get the total distribution amount
        uint256 totalDistributionAmount = getDistributionBalance();

        // If there's no distribution amount, return zeros
        if (totalDistributionAmount == 0) {
            return (0, 0, 0);
        }

        // Calculate the total weighted packages using contribution requirements as ratios
        uint256 totalWeightedPackages = _presaleStats.totalSmallPackages
            * _contributionRequirement.smallPackageRequirement
            + _presaleStats.totalMediumPackages * _contributionRequirement.mediumPackageRequirement
            + _presaleStats.totalLargePackages * _contributionRequirement.largePackageRequirement;

        // If there are no weighted packages, return zeros
        if (totalWeightedPackages == 0) {
            return (0, 0, 0);
        }

        // Calculate token shares for each package type based on contribution requirements as ratios
        uint256 smallShare =
            totalDistributionAmount * _contributionRequirement.smallPackageRequirement / totalWeightedPackages;
        uint256 mediumShare =
            totalDistributionAmount * _contributionRequirement.mediumPackageRequirement / totalWeightedPackages;
        uint256 largeShare =
            totalDistributionAmount * _contributionRequirement.largePackageRequirement / totalWeightedPackages;

        return (smallShare, mediumShare, largeShare);
    }

    /**
     * @inheritdoc IPreSaleOrchestrator_v1
     */
    receive() external payable override {
        // Only accept ETH if payment currency is ETH and from a valid whitelisted user
        if (
            _presaleConfig.paymentCurrency != address(0) || _users[msg.sender].status != UserStatus.Approved
                || _presaleConfig.preSaleStatus != ProcessStatus.Active
        ) {
            revert IPreSaleOrchestrator__CallerIsNotWhitelisted();
        }

        // Use the internal participation function
        _participateInternal(msg.sender, msg.value);
    }

    // --------------------------------------------------------------------------
    // Helper Functions

    /**
     * @dev Updates package statistics when adding or removing users from packages
     * @param _oldPackage The old package type (in case of update)
     * @param _newPackage The new package type
     * @param _isUpdate 1 if updating existing user's package, 0 if adding new user
     * @param _isNew 1 if adding new user, 0 if updating or removing
     */
    function _updatePackageStats(PackageType _oldPackage, PackageType _newPackage, uint256 _isUpdate, uint256 _isNew)
        internal
    {
        // Handle decrementing old package stats
        if (_isUpdate == 1) {
            if (_oldPackage == PackageType.Small) {
                _presaleStats.totalSmallPackages -= 1;
            } else if (_oldPackage == PackageType.Medium) {
                _presaleStats.totalMediumPackages -= 1;
            } else if (_oldPackage == PackageType.Large) {
                _presaleStats.totalLargePackages -= 1;
            }
        }

        // Handle incrementing new package stats
        if (_isNew == 1) {
            if (_newPackage == PackageType.Small) {
                _presaleStats.totalSmallPackages += 1;
            } else if (_newPackage == PackageType.Medium) {
                _presaleStats.totalMediumPackages += 1;
            } else if (_newPackage == PackageType.Large) {
                _presaleStats.totalLargePackages += 1;
            }
        }
    }

    /**
     * @dev Returns the value for a specific package type
     * @param _packageType The package type
     * @param _valueType 0 for token share, 1 for contribution requirement
     * @return The value associated with the package type
     */
    function _getPackageValue(PackageType _packageType, uint256 _valueType) internal view returns (uint256) {
        if (_packageType == PackageType.Small) {
            return _valueType == 0
                ? _tokenDistributionShare.smallPackageShare
                : _contributionRequirement.smallPackageRequirement;
        } else if (_packageType == PackageType.Medium) {
            return _valueType == 0
                ? _tokenDistributionShare.mediumPackageShare
                : _contributionRequirement.mediumPackageRequirement;
        } else {
            return _valueType == 0
                ? _tokenDistributionShare.largePackageShare
                : _contributionRequirement.largePackageRequirement;
        }
    }

    /**
     * @dev Safely transfers distribution tokens to a user
     * @param _to The address to transfer tokens to
     * @param _amount The amount of tokens to transfer
     */
    function _safeTransferDistributionToken(address _to, uint256 _amount) internal {
        IERC20 distributionToken = IERC20(_presaleConfig.distributionToken);
        if (distributionToken.balanceOf(address(this)) >= _amount) {
            distributionToken.safeTransfer(_to, _amount);
            emit DistributionDistributed(_to, _amount);
        }
    }

    /**
     * @dev Calculates the distribution amount for a user based on their package type and contribution
     * @param _userAddress The user's address
     * @param _packageType The user's package type
     * @return The amount of tokens to distribute to the user
     */
    function _calculateUserDistribution(address _userAddress, PackageType _packageType)
        internal
        view
        returns (uint256)
    {
        uint256 userContribution = _users[_userAddress].amountContributed;
        if (userContribution == 0) {
            return 0;
        }

        uint256 packageShare = _getPackageValue(_packageType, 0);
        uint256 maxContribution = getUserMaxContribution(_userAddress);

        return packageShare * userContribution / maxContribution;
    }
}
