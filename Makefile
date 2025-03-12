.PHONY: clean
clean: # Remove build artifacts
	@forge clean

.PHONY: build
build:
	@forge build

.PHONY: deploy-erc20-issuance
deploy-erc20-issuance:
	@forge script script/DeployERC20Issuance_v1.s.sol --rpc-url optimism-sepolia --verify --broadcast -vvv