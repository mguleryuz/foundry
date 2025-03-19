# Technical Context

## Technology Stack

### Development Framework

- **Foundry**: A Rust-based Ethereum development toolkit
  - **Forge**: Testing framework
  - **Cast**: Command-line tool for contract interaction
  - **Anvil**: Local Ethereum node for development
  - **Chisel**: Solidity REPL for interactive development

### Smart Contract Language

- **Solidity**: Version 0.8.23
- **OpenZeppelin Contracts**: Standard implementations for common patterns
  - ERC20
  - ERC20Capped
  - Ownable

### Networks

- **Sepolia** (Ethereum testnet)
- **Optimism Sepolia** (Layer 2 testnet)

## Development Setup

### Local Development

```shell
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Build the project
forge build

# Run tests
forge test

# Format code
forge fmt

# Run local Ethereum node
anvil

# Deploy contract (example)
forge script script/Counter.s.sol:CounterScript --rpc-url <rpc_url> --private-key <private_key>
```

### Environment Configuration

- `.env` file for storing private configuration
  - API keys
  - Private keys
  - Network endpoints
- Remappings in `remappings.txt` for import path resolution
- Foundry configuration in `foundry.toml`

## Technical Constraints

### Gas Optimization

- Contract code should be optimized for gas efficiency
- Minimize state changes and storage operations

### Security Requirements

- Contracts must implement proper access controls
- Security-critical functions require restricted access
- Error handling should be comprehensive with custom errors

### Compatibility

- Contracts should be compatible with ERC20 token standard
- Must work across multiple Ethereum-compatible networks

## Dependencies

### External Libraries

- **OpenZeppelin Contracts**: For security-audited implementations
  - `@oz/token/ERC20/extensions/ERC20Capped.sol`
  - `@oz/access/Ownable.sol`

### Internal Dependencies

- Custom interfaces (e.g., `IERC20Issuance_v1`)
- Other internal contracts as they're developed

## Testing Strategy

- Unit tests for individual contract functions
- Integration tests for contract interactions
- Fuzz testing with configurable runs (256 by default)
- Network-specific tests for deployment validation
