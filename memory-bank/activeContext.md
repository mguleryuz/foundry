# Active Context

## Current Focus

The project is currently focusing on the development of two main smart contracts:

1. **ERC20Issuance_v1**: A token issuance contract that allows for controlled minting and burning of ERC20 tokens

   - This contract is mostly complete with core functionality implemented
   - It extends ERC20Capped and Ownable from OpenZeppelin
   - Includes whitelist functionality for controlling who can mint/burn tokens

2. **PreSaleOrchestrator_v1**: A contract for managing token pre-sales
   - Interface design is now complete with clear token flow management
   - Defines a comprehensive presale workflow with whitelist, contribution, and distribution phases
   - Uses dynamic calculations for token distribution based on package types

## Recent Changes

- Initial setup of the Foundry development environment
- Implementation of the ERC20Issuance_v1 contract
- Creation of the interface for ERC20Issuance_v1
- Design and refinement of the IPreSaleOrchestrator_v1 interface
- Improved naming conventions for clearer token flow (ContributionRequirement vs TokenDistributionShare)
- Setup of multi-network configuration for Sepolia and Optimism Sepolia

## Next Steps

1. **Implement PreSaleOrchestrator_v1 based on the interface**:

   - Develop contract logic for whitelist management
   - Implement dynamic calculation of token distribution shares
   - Implement dynamic calculation of contribution requirements
   - Create distribution mechanism based on user participation

2. **Develop comprehensive tests**:

   - Unit tests for all contract functions
   - Integration tests for contract interactions
   - Fuzz tests for edge cases

3. **Network deployment and verification**:
   - Deploy to Sepolia testnet
   - Deploy to Optimism Sepolia testnet
   - Verify contracts on Etherscan

## Active Decisions and Considerations

### Design Decisions

- **Versioning Strategy**: Contracts are versioned (v1) to allow for future upgrades
- **Interface Separation**: Clear separation between interfaces and implementations
- **Access Control**: Using whitelist pattern for minting/burning permissions and presale management
- **Dynamic Pricing Model**: Token distribution and contribution requirements are calculated dynamically based on total tokens and whitelist data
- **Multi-Currency Support**: Presale can accept ETH or any ERC20 token as payment

### Technical Considerations

- **Gas Optimization**: Need to ensure efficient gas usage in all operations
- **Security**: Access controls must be properly implemented and tested
- **Multi-network Support**: Contracts should work identically across different networks
- **View Function Limitations**: Need to ensure that view functions don't emit events since they can't modify state

### Open Questions

1. What specific presale incentives should be implemented for different package types?
2. Should there be vesting periods after token distribution?
3. What mechanisms should be in place to handle edge cases like underfunded presales?
