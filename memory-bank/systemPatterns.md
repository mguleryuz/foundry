# System Architecture and Patterns

## Overall Architecture

This project uses a modular smart contract architecture with clear separation of concerns:

1. **ERC20Issuance_v1**: Handles token creation and management
2. **PreSaleOrchestrator_v1**: Manages the presale process, whitelist, and token distribution

Each contract has a dedicated interface that defines its public API, promoting clean contract interactions and easier testing.

## Design Patterns

### Interface-Implementation Separation

All contracts follow a strict interface-implementation pattern:

- Interface files (e.g., `IPreSaleOrchestrator_v1.sol`) define the contract's public API
- Implementation files (e.g., `PreSaleOrchestrator_v1.sol`) provide the actual functionality

This separation allows for:

- Clear contract boundaries
- Easier upgrades in the future
- Simplified testing through mock implementations

### Access Control

Multiple levels of access control are implemented:

- **Admin Control**: Admin-only functions for critical operations
- **Whitelist Control**: User validation for participation
- **Status Control**: Functions that validate the current process status

### State Machine

The PreSaleOrchestrator contract implements a state machine pattern:

- **Process Statuses**: Inactive, Active, Paused, Ended
- **Phase Transitions**: Whitelist → Presale → Distribution
- **Status Checks**: Guard functions against invalid state transitions

### Data Structures

Key data structures include:

- **User**: Stores user status, package type, and contribution amount
- **PresaleConfig**: Manages the status of the whitelist and presale periods
- **PresaleStats**: Tracks total packages and participation metrics
- **ContributionRequirement**: Defines how much users need to contribute
- **TokenDistributionShare**: Defines how tokens are distributed proportionally

### Dynamic Calculation

The contract uses dynamic calculations for:

- **Package Pricing**: Based on distribution token amount and package types
- **Token Distribution**: Proportional to user contribution and package type
- **Minimum Requirements**: 50% minimum contribution enforcement

## Component Relationships

```
┌───────────────────┐       ┌─────────────────────────┐
│                   │       │                         │
│  ERC20Issuance_v1 │◄──────┤  PreSaleOrchestrator_v1 │
│                   │       │                         │
└───────────────────┘       └─────────────────────────┘
        ▲                              ▲
        │                              │
        │                              │
┌───────────────────┐       ┌─────────────────────────┐
│                   │       │                         │
│  IErc20Issuance_v1│       │IPreSaleOrchestrator_v1  │
│                   │       │                         │
└───────────────────┘       └─────────────────────────┘
```

The PreSaleOrchestrator_v1 contract interacts with the ERC20Issuance_v1 contract (or any ERC20 token) for distribution token management.

## Implementation Details

### PreSaleOrchestrator_v1

- **Admin Management**:

  - Multiple admins can be added or removed
  - Protection against self-removal
  - Only admins can configure critical parameters

- **Whitelist Management**:

  - Individual and batch user whitelisting
  - Support for different package types
  - Ability to revoke or reject users
  - Separate mechanisms for tracking user status and statistics

- **Statistics Management**:

  - Automatic tracking of presale statistics within whitelist management functions
  - Intelligent detection of new users through empty address checks
  - Proper updating of stats during package type changes
  - Accurate tracking of total packages by type and overall participation metrics

- **Presale Process**:

  - Strict phase control (whitelist → presale → distribution)
  - Pause/resume functionality for each phase
  - Dynamic calculation of contribution requirements

- **Participation Handling**:

  - Support for both ETH and ERC20 payments
  - Multiple participation methods:
    - Direct ETH transfers via receive() function
    - Explicit participate() function for ETH payments
    - participateInPresale() function for backward compatibility
    - participateWithERC20() for token payments
  - Shared internal participation logic with \_participateInternal
  - Enforces minimum and maximum contribution limits

- **Distribution Logic**:
  - Proportional distribution based on contribution
  - Fixed token shares for testing with 1:3:10 ratio
  - Safety checks for sufficient token balance
  - Automatic transfer to participants

### ERC20Issuance_v1

- **Token Management**:
  - Standard ERC20 functionality
  - Capped supply to prevent inflation
  - Admin-controlled minting and burning

## Key Technical Decisions

- **Use of OpenZeppelin**: Leveraging battle-tested contracts for standard functionality
- **Gas Optimization**: Careful considerations for batch operations and storage
- **Multi-network Support**: Contracts designed to work on multiple EVM chains
- **Versioning Strategy**: Contracts versioned for future upgrades
- **Error Handling**: Custom errors with descriptive names for easier debugging

## Security Considerations

- **Access Control**: Strict control over admin functions
- **Input Validation**: Thorough checks on all user inputs
- **State Guards**: Preventing invalid state transitions
- **Reentrancy Protection**: Following checks-effects-interactions pattern
- **Pause Functionality**: Ability to pause operations in emergency
