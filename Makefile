.PHONY: clean
clean: # Remove build artifacts
	@forge clean

.PHONY: build
build:
	@forge build

.PHONY: deploy
deploy:
	@forge script script/DeployERC20Issuance_v1.s.sol --rpc-url optimism-sepolia --verify --broadcast -vvv
