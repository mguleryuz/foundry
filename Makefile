.PHONY: clean
clean: # Remove build artifacts
	@forge clean

.PHONY: build
build:
	@forge build

.PHONY: fund-private-key
fund-private-key:
	@eval $$(cat .env | grep PRIVATE_KEY) && \
	cast send --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --value 100ether $$(cast wallet address --private-key $$PRIVATE_KEY)

.PHONY: deploy-erc20-issuance
deploy-erc20-issuance:
	@forge script script/DeployERC20Issuance_v1.s.sol --rpc-url optimism-sepolia --verify --broadcast -vvv

.PHONY: deploy-presale-orchestrator
deploy-presale-orchestrator:
	@if [ -z "$(--chain-alias)" ]; then \
		forge script script/DeployPresaleOrchestrator_v1.s.sol --rpc-url anvil --broadcast -vvv; \
	else \
		forge script script/DeployPresaleOrchestrator_v1.s.sol --rpc-url $(--chain-alias) --verify --broadcast -vvv; \
	fi