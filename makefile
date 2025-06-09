-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil fallbackExp

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
BACK_ANVIL_KEY := 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
DEFAULT_ZKSYNC_LOCAL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
all: clean remove install update build help
help:
	@echo " Usage:"
	@echo "   make deploy [ARGS=...]\n    example: make deploy ARGS='--network sepolia'"
	@echo ""
	@echo "   make deployToken [ARGS=...]\n    example: make deployToken ARGS='--network arbisepolia'"


# Clean the repo
clean :; forge clean

# Remove modules to reset modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# install :; forge install cyfrin/foundry-devops@0.1.0 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-commit && forge install foundry-rs/forge-std@v1.9.5 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

zkbuild :; forge build --zksync

test :; forge test

# zktest :; foundryup-zksync && forge test --zksync && foundryup
zktest :; forge test --zksync

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 12

NETWORK_ARGS := --rpc-url http://127.0.0.1:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast -vvvv

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(ACCOUNT_SEPOLIA) --broadcast --sender $(ACCOUNT_SEPOLIA) -vvvv
endif

ifeq ($(findstring --network arbiSepolia,$(ARGS)),--network arbiSepolia)
	NETWORK_ARGS := --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --account $(ACCOUNT_ARBITRUM) --broadcast --sender $(ACCOUNT_ARBITRUM) --verify --arbiscan-api-key $(ARBISCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network holesky,$(ARGS)),--network holesky)
	NETWORK_ARGS := --rpc-url $(HOLESKY_RPC_URL) --account $(ACCOUNT_HOLESKY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

fallbackExp:
	@forge script script/FallbackExp.s.sol:Exp $(NETWORK_ARGS)
falloutExp:
	@forge script script/FalloutExp.s.sol:Exp $(NETWORK_ARGS)
coinFlipExp:
	@forge script script/CoinFlipExp.s.sol:Exp $(NETWORK_ARGS)
telephoneExp:
	@forge script script/TelephoneExp.s.sol:Exp $(NETWORK_ARGS)
tokenExp:
	@forge script script/TokenExp.s.sol:Exp $(NETWORK_ARGS)
delegationExp:
	@forge script script/DelegationExp.s.sol:Exp $(NETWORK_ARGS)
forceExp:
	@forge script script/ForceExp.s.sol:OnChainExp $(NETWORK_ARGS)