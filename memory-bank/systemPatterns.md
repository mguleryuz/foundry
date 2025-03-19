# System Patterns

## Architecture Overview

The project follows a modular smart contract architecture with clear separation of concerns between token issuance and token sale orchestration. The architecture is designed to be secure, extensible, and compatible with established Ethereum standards.

## Design Patterns

### Access Control Patterns

1. **Ownership Pattern**: Using OpenZeppelin's `Ownable` for administrative control
2. **Whitelist Pattern**: Custom whitelist implementation for minting permissions
3. **Modifiers**: Custom modifiers like `onlyMinter` for function access control

### Token Patterns

1. **ERC20 Standard**: Implementation of the ERC20 token standard for compatibility
2. **Capped Supply**: Using `ERC20Capped` to limit maximum token supply
3. **Custom Decimals**: Configurable token decimals for flexibility

### Version Control Pattern

1. **Versioned Contracts**: Contracts follow a versioning scheme (e.g., `ERC20Issuance_v1`) for clear upgrade paths
2. **Interface Separation**: Interfaces (e.g., `IERC20Issuance_v1`) defined separately from implementations

## Component Relationships

```
                      +----------------+
                      |                |
                      |    Ownable     |
                      |                |
                      +-------+--------+
                              |
                              |
+----------------+    +-------+--------+    +----------------+
|                |    |                |    |                |
| IERC20Issuance +---->  ERC20Issuance |    |  ERC20Capped  |
|                |    |                |    |                |
+----------------+    +-------+--------+    +----------------+
                              |
                              |
                     +--------+---------+
                     |                  |
                     | PreSaleOrchestrator |
                     |                  |
                     +------------------+
```

## Key Technical Decisions

1. **Foundry as Development Environment**:

   - Faster compilation and testing
   - Advanced testing capabilities with fuzzing
   - Rust-based performance benefits

2. **OpenZeppelin Integration**:

   - Leveraging battle-tested contract implementations
   - Follows well-established security patterns
   - Reduced need for custom security implementations

3. **Explicit Interface Definition**:

   - Clear contract interfaces with IERC20Issuance_v1
   - Well-documented function signatures and error handling
   - Type-safe interactions between contracts

4. **Multi-network Support**:
   - Configuration for multiple test networks
   - Consistent deployment across different environments

## Security Considerations

1. **Access Control**: Strict validation of caller permissions for sensitive operations
2. **Supply Management**: Enforced supply caps to prevent inflation attacks
3. **Error Handling**: Custom errors for better debugging and gas efficiency
4. **Upgrade Strategy**: Versioned contracts facilitate future upgrades if needed
