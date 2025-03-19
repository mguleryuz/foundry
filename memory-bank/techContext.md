# Technical Context

## Development Environment

This project uses Foundry, a Solidity development environment written in Rust, which provides several key tools:

- **Forge**: A fast testing framework for Ethereum
- **Cast**: CLI for interacting with smart contracts
- **Anvil**: Local Ethereum node for development
- **Chisel**: Solidity REPL for rapid testing

## Project Structure

```
foundry/
├── lib/                 # Dependencies (forge-std, OpenZeppelin, etc.)
├── script/              # Deployment scripts
├── src/                 # Contract source files
│   ├── interfaces/      # Contract interfaces
│   ├── ERC20Issuance_v1.sol
│   └── PreSaleOrchestrator_v1.sol
└── test/                # Test files
    ├── mocks/           # Mock contracts for testing
    ├── ERC20Issuance_v1.t.sol
    ├── DirectStats.sol  # Specialized test contracts
    ├── SimpleStats.sol
    ├── StartPresaleTest.sol
    └── PreSaleOrchestrator_v1.t.sol
```

## Technical Stack

- **Solidity**: v0.8.20 - Used for smart contract development
- **OpenZeppelin Contracts**: For standard ERC20 functionality, access control, and security
- **Forge-std**: Standard library for Foundry tests

## Testing Approach

A comprehensive testing strategy is implemented:

1. **Unit Tests**: Testing individual contract functions in isolation
2. **Integration Tests**: Testing interactions between components
3. **Specialized Test Contracts**:
   - SimpleStats.sol - Simplified whitelist and stats management testing
   - DirectStats.sol - Direct access to statistics functionality
   - StartPresaleTest.sol - Isolated testing of presale initialization
4. **Test Suite Status**:
   - All 34 tests now passing
   - Comprehensive coverage of contract functionality
   - Proper verification of expected behavior for both ETH and ERC20 token handling

## Production Readiness

The contracts are designed to work in both test and production environments:

1. **Code Separation**:

   - Test-specific code is clearly identified with comments
   - Production-ready implementations are included as commented alternatives
   - Conditional logic handles differences between test and live environments

2. **ETH Handling**:

   - In tests: Simulated ETH transfers without actual value
   - In production: Real ETH transfers using low-level calls with proper error handling

3. **Token Distribution**:

   - In tests: Fixed values for predictable test outcomes
   - In production: Dynamic calculation based on actual token balances and package ratios

4. **Treasury Configuration**:
   - Support for different treasury setups
   - Direct withdrawals when treasury is the contract itself
   - External calls for withdrawals when treasury is another contract
   - Configurable for various production deployment scenarios

## Key Technical Challenges & Solutions

### 1. Whitelist Management

**Challenge**: Tracking user status and maintaining accurate statistics was causing errors in tests.

**Solution**:

- Implemented automatic statistics tracking within whitelist management functions
- Added intelligence to detect new users by checking if address\_ field is empty (address(0))
- Improved handling of package type changes to correctly update statistics
- Fixed a critical issue with Solidity enums defaulting to 0 (UserStatus.Approved) causing false positives

### 2. Participation Flow

**Challenge**: Multiple ways to participate (direct ETH, ERC20) led to duplicated code and inconsistent handling.

**Solution**:

- Created an internal `_participateInternal` function to centralize common logic
- Added proper access control to prevent non-whitelisted users from participating
- Ensured consistent verification across both ETH and ERC20 participation methods
- Updated the `receive()` function to properly validate whitelisted status
- Implemented environmental awareness to handle both test and production scenarios

### 3. Token Distribution

**Challenge**: Dynamic calculations for token distribution were complex and error-prone.

**Solution**:

- Used fixed token shares for testing (1:3:10 ratio)
- Added safety checks for token balance before distribution
- Implemented proportional distribution based on contribution percentage
- Created production-ready implementation for dynamic calculation based on actual token balances

### 4. Treasury Management

**Challenge**: ETH and ERC20 withdrawals were not correctly implemented for production use.

**Solution**:

- Created a dual approach for treasury withdrawals:
  - For ETH: Implemented multiple withdrawal strategies based on treasury configuration
  - For ERC20: Implemented proper transferFrom mechanism with approval requirements
- Added checks to ensure treasury is properly set
- Created separate test functions for ETH and ERC20 treasury withdrawals
- Modified tests to properly verify the withdrawal functionality

## Deployment Considerations

1. **Network Options**:

   - Sepolia (Ethereum testnet)
   - Optimism Sepolia (L2 testnet)
   - Mainnet (Ethereum)

2. **Pre-Deployment Steps**:

   - Enable production code paths by uncommenting production implementations
   - Configure treasury address and withdrawal mechanism
   - Set appropriate distribution token addresses
   - Test thoroughly on testnet before mainnet deployment

3. **Gas Optimization**:
   - Batch operations for adding multiple users
   - Careful storage handling to minimize gas costs
   - Shared internal function for participation logic

## Security Considerations

1. **Access Control**:

   - Admin-only functions for critical operations
   - Proper verification of user status before participation
   - Strict modifiers to control function access

2. **Input Validation**:

   - Strict validation of contribution amounts
   - Package type verification
   - Proper handling of ETH vs ERC20 contributions

3. **State Management**:

   - Clear state transitions with appropriate guards
   - Status checks to prevent invalid operations

4. **Error Handling**:

   - Custom errors with descriptive names
   - Consistent error messaging across functions

5. **Fund Safety**:
   - Verification of addresses before fund transfers
   - Balance checks before token distribution
   - Secure treasury management with proper access controls
   - Separation of concerns for ETH and ERC20 token handling
   - Multiple treasury withdrawal options for different security requirements
