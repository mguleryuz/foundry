# Active Context

## Current Focus

The current focus is on ensuring the PreSaleOrchestrator_v1 contract is fully production-ready without any test-specific code. The contract manages a presale process that involves:

1. Whitelisting users with different package types
2. Handling deposits/contributions of distribution tokens
3. Calculating token distribution dynamically based on participation
4. Managing both ETH and ERC20 tokens for participation and treasury operations
5. Ensuring all functionality works identically in production environments

## Recent Changes

1. **Production-Ready Token Distribution**: Replaced hardcoded test values in `calculateTokenDistribution` with dynamic calculation based on actual token balances and package distribution.

2. **ETH Transfer Handling**: Improved the `_participateInternal` function to always forward real ETH transfers to the treasury, removing test-specific conditional logic.

3. **Treasury Withdrawal Implementation**: Enhanced the `withdrawTreasury` function with proper implementation for external treasury contracts, removing test-specific event emissions.

4. **Test Updates**: Modified tests to work with production-ready code, using real ETH transfers and appropriate assertions for dynamic token calculation.

5. **Core Principle Establishment**: Established the principle that smart contracts should not contain any hardcoded test values, and tests should simulate production behavior.

## Key Principles

1. **No Hardcoded Test Values**: Contracts should not contain any hardcoded values specifically for testing purposes.

2. **Tests Simulate Production**: Test environments should simulate production behavior as much as possible.

3. **Modify Tests, Not Contracts**: If test-specific behavior is needed, modify the tests rather than adding conditional logic to the contract.

4. **Production-Ready Always**: Maintain production-ready code at all times, avoiding any test-specific paths or behavior.

## Next Steps

1. **Gas Optimization**: Review gas usage and optimize the contract for production use.

2. **Deployment Scripts**: Create deployment scripts for mainnet and testnet environments, ensuring proper configuration for production.

3. **Audit**: Conduct a thorough security audit before deploying to production.

4. **Documentation**: Ensure all production-specific code changes are properly documented for the deployment team.

## Active Decisions and Considerations

1. **Token Distribution Calculation**: Using actual token balance and package distribution for calculating share values.

2. **ETH Transfer Management**: Direct ETH transfers to treasury with proper error handling.

3. **Treasury Flexibility**: Supporting multiple treasury configurations:

   - Treasury as this contract (direct transfer)
   - Treasury as external contract (call withdraw function)

4. **Test Adaptation**: Maintaining test coverage by adapting tests to work with production code rather than modifying the contract for tests.
