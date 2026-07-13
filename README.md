# Decentralized Stablecoin
A decentralized,  overcollateralized stablecoin  protocol that enables users to deposit WETH or WBTC as collateral and mint a USD-pegged stablecoin. The protocol maintains stability through collateralization, health factor enforcement,  liquidation mechanisms, and decentralized price feeds powered by Chainlink.

## Features
* **Overcollateralized Stablecoin:** Deposit WETH or WBTC  as collateral to mint  a decentralized USD-pegged stablecoin.
* **Exogenous Collateral:** Supports WETH and WBTC  as collateral assets.
* **Algorithmic Minting:** Stablecoin issuance is governed by protocol collateralization rules.
* **Health Factor System:** Continuously monitors  collateralization to help maintain protocol solvency.
* **Liquidation Mechanism:** Enables liquidation of undercollateralized positions to preserve protocol stability.
* **Chainlink Price Feed Integration:** Utilizes decentralized price oracles for accurate collateral valuation.
* **Protocol-Controlled Minting & Burning:** Stablecoin supply is securely  managed by the `DSCEngine`.
* **Permissionless User Interactions:** Users can deposit collateral, mint DSC, redeem collateral, and participate in liquidations.
* **Gas Optimized:** Uses custom errors and efficient Solidity patterns to reduce gas costs.
* **Comprehensive Testing:** Includes unit, fuzz, and invariant tests built with Foundry.
* **OpenZeppelin Security:** Built on audited OpenZeppelin ERC20 and access  control contracts.



## Technology Stack (Technologies Used)



## Getting Started
### Prerequisites
* [FOUNDRY](https://www.getfoundry.sh/introduction/installation) - Ethereum development toolchain
    * Verify installation: `forge --version`
* [GIT](https://git-scm.com/) - - Version control
     * Verify installation: `git --version`

### Installation
 1. Clone the repository:
    ```shell
        git clone https://github.com/legendarycode3/decentralized-stablecoin
    ```
    ```shell
        cd decentralized-stablecoin
    ```
2. Install dependencies:
   ```shell
     make install
   ```
3. Build the project/contract:
   ```shell
     make build
   ```

### Environment Setup
1. ****Configure your .env file:**** </br>
Create .env file in project root: </br>
   ```shell
      SEPOLIA_RPC_URL=your_sepolia_rpc_url
      ETHERSCAN_SEPOLIA_API_KEY=your_etherscan_api_key
   ```
2. ****Get testnet ETH:**** </br>
      * ETH Sepolia Faucet: [Eth Sepolia Faucet](https://cloud.google.com/application/web3/faucet/ethereum/sepolia) 


## Usage



## Testing
### Running Tests
```shell
   # Run all tests
   forge test

   # Run with verbosity
   forge test -vvv

   # Run with gas reporting
   forge test --gas-report

   # Run specific test file
   forge test --mt test/unit/DSCEngineTest.t.sol

   # Generate coverage report
   forge coverage

   # Run invariant tests
   forge test --match-path test/invariants/Invariants.t.sol
```



## Project Structure
```shell 
 ├── script                                                           # Deployment and network configuration scripts 
 │   ├── DeployDSC.s.sol                                              # Main deployment script for the Decentralized Stablecoin protocol
 │   └── HelperConfig.s.sol                                           # Network-specific configuration (price feeds, collateral tokens, etc.)                                            ├── src                                                              # Smart contract source code
 │   │   └── OracleLib.sol                                            # Oracle utility library for Chainlink price feed safety and stale price checks
 │   ├── DecentralizedStableCoin.sol                                  # ERC20 stablecoin implementation responsible for minting and burning DSC
 │   └── DSCEngine.sol                                                # Core protocol logic (collateral deposits, minting, redemption, liquidation, health factor)
 │   ├── test                                                         # Smart contract test suite
 │   ├── fuzz
 │   │   ├── Handler.t.sol                                            # Handler contract used for invariant fuzz testing
 │   │   └── Invariants.t.sol                                         # Invariant tests validating protocol-wide properties
 │   │
 │   ├── mocks                                                        # Mock contracts for local development and testing
 │   │   ├── ERC20Mock.sol                                            # Mock ERC20 collateral token
 │   │   ├── MockFailedMintDSC.sol                                    # Mock contract simulating failed DSC mint operations
 │   │   ├── MockFailedTransfer.sol                                   # Mock contract simulating failed token transfers
 │   │   └── MockV3Aggregator.sol                                     # Mock Chainlink price feed aggregator
 │   │
 │   └── unit
 │       └── DSCEngineTest.t.sol                                      # Unit tests covering the core protocol functionality
 │
 ├── lib
 │   ├── forge-std/                                                   # Foundry standard testing library
 │   ├── chainlink-brownie-contracts/                                 # Chainlink smart contract interfaces and utilities
 │   └── openzeppelin-contracts/                                      # OpenZeppelin audited contract library
 │
 ├── foundry.toml                                                     # Foundry project configuration
 ├── Makefile                                                         # Build, test, deployment, and  utility commands
 └── README.md                                                        # Project documentation
```

 
## Security Considerations
* ****Reentrancy Protection:**** The protocol uses OpenZeppelin's `ReentrancyGuard` to protect functions that transfer collateral or perform state-changing operations involving external token contracts. By preventing nested calls into sensitive functions such as collateral deposits, redemptions, minting, and liquidations, the protocol mitigates classic reentrancy attacks that could otherwise manipulate internal accounting or drain collateral. 
* ****Checks-Effects-Interactions (CEI) Pattern:**** The protocol consistently follows the Checks-Effects-Interactions pattern. Internal state variables are updated before interacting ensuring that malicious external contracts cannot exploit intermediate states during execution. This design significantly reduces the attack surface for reentrancy and maintains consistent protocol accounting.
* ****Oracle Security:**** Collateral valuations rely on Chainlink price feeds with additional stale-price validation through `OracleLib`. Rather than directly consuming the latest oracle response, the protocol verifies that price data is sufficiently recent before using it in collateral calculations. This helps protect the protocol against stale oracle data that could otherwise lead to incorrect collateral valuations, unsafe minting, or unfair liquidations.
* ****Collateral Whitelisting:**** Only explicitly approved collateral assets can be deposited into the protocol. Every collateral token must have an associated trusted price feed configured during deployment, preventing users from depositing unsupported or malicious ERC-20 tokens whose values cannot be safely verified.
* ****Health Factor Enforcement:**** Every operation capable of increasing protocol risk, including minting, collateral redemption, and liquidation is protected by health factor validation. Users cannot create or maintain positions that fall below the minimum collateralization threshold, ensuring the protocol remains fully overcollateralized and reducing the likelihood of bad debt.
* ****Overcollateralization Requirement:**** The stablecoin is fully backed by excess collateral rather than relying on algorithmic stabilization mechanisms. Users must maintain collateral whose value exceeds their outstanding debt according to the configured liquidation threshold, providing a safety buffer against normal market volatility.
* ****Liquidation Incentives:**** The protocol rewards liquidators with a predefined liquidation bonus when repaying the debt of undercollateralized positions. This incentive encourages market participants to promptly remove risky positions from the system, promptly remove risky positions from the system, helping maintain protocol solvency during periods of market stress. 
* ****ERC-20 Transfer Validation:**** All ERC-20 token transfers verify the success of external transfer operations before continuing execution. Transactions immediately revert if a transfer fails, preventing inconsistent accounting or partially completed operations that could otherwise compromise protocol integrity.
* ****Immutable Core Dependencies:**** The stablecoin contract address is stored as an immutable variable during deployment and cannot be modified afterward. This prevents administrative replacement of the stablecoin contract reducing governance risks and ensuring users always interact with the originally deployed system.
* ****Precision-Safe Arithmetic:**** The protocol performs all financial calculations using fixed-point arithmetic with standardized precision constants. This avoids floating-point inaccuracies while minimizing rounding errors during collateral valuation, health factor calculations, and liquidation logic.


### Known Risks & Assumptions
* ****Oracle Dependency:**** The protocol depends on external Chainlink price feeds for collateral valuation. Although stale price checks reduce oracle-related risks, prolonged oracle outages, delayed updates, or unexpected oracle failures could temporarily affect collateral valuation and liquidation functionality. The protocol assumes trusted oracle infrastructure remains available and operational.
* ****Fee-on-Transfer Token Compatibility:**** The protocol assumes supported collateral tokens transfer the exact amount requested during deposits and withdrawals. Fee-on-transfer, rebasing, or deflationary ERC-20 tokens may result in discrepancies between recorded collateral balances and actual token balances held by the protocol. Only standard ERC-20 collateral assets should be supported unless additional accounting logic is implemented.
* ****Extreme Market Conditions:**** The liquidation mechanism assumes collateral maintains sufficient value to incentivize liquidators. During severe market crashes where collateral value falls below outstanding debt, liquidations may become economically unattractive, potentially resulting in protocol bad debt. This limitation is common among overcollateralized lending protocols and should be considered when selecting supported collateral assets and liquidation parameters.
* ****Oracle Decimal Assumptions:**** The protocol assumes supported Chainlink price feeds use the expected decimal precision during price normalization. Introducing price feeds with different decimal configurations without adjusting precision calculations may result in inaccurate collateral valuations. Future protocol upgrades should normalize oracle decimals dynamically where appropriate.
* ****No Emergency Pause Mechanism:**** The protocol intentionally operates without an emergency pause or circuit breaker. While this increases decentralization by eliminating privileged administrative intervention, it also means protocol operations cannot be temporarily suspended in the event of unexpected vulnerabilities, oracle failures, or ecosystem-wide incidents.
* ****Governance Assumptions:**** The current implementation assumes the set of supported collateral assets and their associated price feeds remain fixed after deployment. Since no governance mechanism exists to modify protocol parameters, any future changes would require deploying a new version of the protocol. This immutable design minimizes governance risk but reduces operational flexibility.
* ****User Responsibility:**** Users remain responsible for monitoring their own health factor and maintaining sufficient collateralization. Significant market volatility may rapidly reduce collateral value, causing positions to become eligible for liquidation. The protocol does not automatically rebalance user positions or provide protection against liquidation resulting from market movements.


### Recommended Practices
* Always maintain health factor greater than "1.0". Users are encouraged to keep it well above 1.0 (e.g., above 1.5) as a safety buffer against market volatility.
* Monitor collateral prices and adjust positions proactively.
* Use `getHealthFactor()` before large redemptions.
* Consider gas costs  when liquidating small positions.
* Deposit additional collateral if your health factor approaches the minimum threshold. Acting proactively is generally preferable to waiting until liquidation becomes imminent.
* Avoid borrowing the maximum amount permitted by your collateral. Leaving unused borrowing capacity can help absorb unexpected market movements without immediately putting your position at risk.
* Understand the protocol's liquidation mechanism before minting stablecoins. Familiarity with liquidation thresholds, bonuses, and repayment requirements helps you make informed borrowing decisions.
* Read the project documentation carefully before interacting with the protocol to understand its collateral requirements, minting process,


### Audit Status
****⚠️ NOT AUDITED**** - Do not deploy to mainnet or use with real funds without professional security audit.



## Resources
* [Solidity Documentation](https://docs.soliditylang.org/en/v0.8.36/)
* [Chainlink](https://docs.chain.link/data-feeds/price-feeds)
* [MakerDAO Technical Docs](https://docs.makerdao.com/)
* [Foundry Book](https://www.getfoundry.sh/)


## Acknowledgments
* Built with [Foundry](https://github.com/foundry-rs/foundry) toolkit
* Uses [Chainlink](https://chain.link/) decentralized oracles
* Inspired by [MakerDAO's](https://makerdao.com/en/) DAI stablecoin architecture
* Security patterns from [ OpenZeppelin](https://www.openzeppelin.com/)
