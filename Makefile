########################################
# MakeFile Configurations
########################################


########################################
# Configuration 
########################################

# Load environment variables from .env file (RPC URLs, PRIVATE_KEY,and more)
-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80



########################################
# Primary Target
########################################
all: clean remove install update build



########################################
# Utility Commands
########################################
# Clean the repo
clean  :; forge clean

help:
	@echo "==========================================="
	@echo "        Foundry Project Commands"
	@echo "==========================================="
	@echo ""
	@echo "Available commands:"
	@echo "  build         - Compile Solidity contracts"
	@echo "  test          - Run the test suite"
	@echo "  test-gas      - Run tests with gas report"
	@echo "  snapshot      - Generate gas snapshot"
	@echo "  format        - Format Solidity code"
	@echo "  clean         - Remove build artifacts"
	@echo "  install       - Install project dependencies"
	@echo "  update        - Update project dependencies"
	@echo "  anvil         - Start a local Anvil node"
	@echo "  deploy        - Deploy contracts"
	@echo "  fund          - Fund deployed contracts"
	@echo "  verify        - Verify contracts on a block explorer"
	@echo "  config        - Show current project configuration"
	@echo ""
	@echo "Usage examples:"
	@echo "  make build"
	@echo "  make test"
	@echo "  make deploy ARGS=\"--network sepolia\""
	@echo "  make deploy ARGS=\"--rpc-url <RPC_URL> --broadcast\""
	@echo "  make fund ARGS=\"--network sepolia\""
	@echo "  make verify ARGS=\"--network sepolia\""
	@echo ""
	@echo "Tip:"
	@echo "  Use the ARGS variable to pass additional Forge CLI options."
	@echo "  Example:"
	@echo "    make deploy ARGS=\"--network sepolia --broadcast --verify\""

format :; forge fmt




########################################
# Dependency Management
########################################
# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install project dependencies
install :; forge install cyfrin/foundry-devops@0.1.0 && forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 && forge install foundry-rs/forge-std@v1.5.3 && forge install openzeppelin/openzeppelin-contracts@v4.8.3 

# Update Dependencies
update:; forge update



########################################
# Build Commands
########################################

# Compile Solidity contracts
build:; forge build

# Run the test suite
test :; forge test 

# Generate coverage report
coverage :; forge coverage --report debug > coverage-report.txt

# Generate gas snapshot
snapshot :; forge snapshot

# Run fuzz tests with more iterations
fuzz:; forge test --fuzz-runs 10000



########################################
# Development Commands
########################################

# Start local Anvil node
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1


########################################
# Network Configuration
########################################
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif



########################################
# Deployment Commands
########################################
# Deploy to Sepolia testnet
deploy:
	@forge script script/DeployDSC.s.sol:DeployDSC $(NETWORK_ARGS)

