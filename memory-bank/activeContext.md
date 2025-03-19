# Active Context

## Current Focus

The project is currently focusing on the development of two main smart contracts:

1. **ERC20Issuance_v1**: A token issuance contract that allows for controlled minting and burning of ERC20 tokens

   - This contract is mostly complete with core functionality implemented
   - It extends ERC20Capped and Ownable from OpenZeppelin
   - Includes whitelist functionality for controlling who can mint/burn tokens

2. **PreSaleOrchestrator_v1**: A contract for managing token pre-sales
   - This contract is in early development stages (file exists but is empty)
   - Will likely interact with the ERC20Issuance_v1 contract for token distribution

## Recent Changes

- Initial setup of the Foundry development environment
- Implementation of the ERC20Issuance_v1 contract
- Creation of the interface for ERC20Issuance_v1
- Setup of multi-network configuration for Sepolia and Optimism Sepolia

## Next Steps

1. **Complete PreSaleOrchestrator_v1 implementation**:

   - Define the interface for pre-sale functionality
   - Implement core sale mechanics
   - Establish integration with ERC20Issuance_v1

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
- **Access Control**: Using whitelist pattern for minting/burning permissions

### Technical Considerations

- **Gas Optimization**: Need to ensure efficient gas usage in all operations
- **Security**: Access controls must be properly implemented and tested
- **Multi-network Support**: Contracts should work identically across different networks

### Open Questions

1. What specific pre-sale mechanics should be implemented in PreSaleOrchestrator_v1?
2. Should there be time-based restrictions on the pre-sale process?
3. What vesting or distribution mechanisms are needed for token distribution?
