# Decentralized Stablecoin
A decentralized,  overcollateralized stablecoin  protocol that enables users to deposit WETH or WBTC as collateral and mint a USD-pegged stablecoin. The protocol maintains stability through collateralization, health factor enforcement,  liquidation mechanisms, and decentralized price feeds powered by Chainlink.



## Project Overview
The `Decentralized Stablecoin (DSC)` is a decentralized, overcollateralized, crypto-backed stablecoin protocol inspired by the core principles of MakerDAO's DAI system. The protocol enables users to deposit approved cryptocurrency collateral, mint a USD-pegged stablecoin (DSC), redeem collateral, repay debt, and participate in liquidations, all without relying on centralized custodians. </br>
The protocol maintains solvency through overcollateralization, real-time price feeds provided by Chainlink oracles, and an automated liquidation mechanism that ensures every DSC token remains sufficiently backed by on-chain collateral. </br>

The system consists of two primary smart contracts: </br>
* ****`DSCEngine`****: The core protocol contract responsible for collateral management, DSC minting and burning, health factor calculations, collateral redemption, and liquidations.
* ****`DecentralizedStableCoin (DSC)`****: An ERC-20 compliant stablecoin contract whose minting and burning are exclusively controlled by the `DSCEngine`, ensuring that new DSC can only be created when sufficient collateral has been deposited.

The protocol is designed with a modular architecture, leveraging OpenZeppelin security standards, Chainlink decentralized price feeds, and a health factor model to maintain protocol solvency and safeguard user funds.
By enforcing collateralization thresholds and continuously monitoring user positions through oracle price data, the protocol minimizes insolvency risk while providing a decentralized alternative to traditional stablecoins.


### Key Features
* Deposit approved collateral assets(e.g., WETH and WBTC).
* Mint a USD-pegged decentralized stablecoin backed by crypto collateral.
* Redeem collateral by repaying outstanding DSC debt.
* Burn DSC to reduce debt obligations.
* Automated health factor calculations to monitor account solvency.
* Liquidation mechanism for undercollateralized positions with liquidator incentives.
* Chainlink price feeds for secure, decentralized asset pricing.
* Reentrancy protection and Checks-Effects-Interactions (CEI) pattern for enhanced security.
* Modular architecture separating token logic from protocol logic.


## Architecture 
The protocol is built around a modular architecture that separates token issuance from protocol logic. This design improves security, maintainability, and extensibility by ensuring each contract has a single responsibility.
```shell
                        +---------------------------+
                        |         User              |
                        +------------+--------------+
                                     |
             Deposit Collateral / Mint / Burn / Redeem
                                     |
                                     v
                    +-------------------------------+
                    |          DSCEngine            |
                    |-------------------------------|
                    | • Collateral Management       |
                    | • Mint DSC                    |
                    | • Burn DSC                    |
                    | • Health Factor               |
                    | • Liquidations                |
                    | • Oracle Price Validation     |
                    +-----+-------------------+-----+
                          |                   |
            Chainlink     |                   | Mint / Burn
            Price Feeds   |                   |
                          v                   v
               +----------------+     +-------------------------+
               |   OracleLib    |     | DecentralizedStableCoin |
               |----------------|     |-------------------------|
               | Stale Price    |     | ERC20 Token             |
               | Validation     |     | Mint                    |
               +----------------+     | Burn                    |
                                      +-----------+-------------+
                                                  |
                                                  |
                                        +---------v---------+
                                        |   Users Hold DSC  |
                                        +-------------------+

                Supported Collateral
        +----------------+   +----------------+
        |      WETH      |   |      WBTC      |
        +----------------+   +----------------+
```

### Core Components
1. ****DSCEngine:**** The `DSCEngine` is the core of the protocol. It manages all business logic and maintains the protocol's solvency. </br>
  Its responsibilities include: </br>
   * Managing collateral deposits.
   * Minting and burning DSC.
   * Redeeming collateral.
   * Monitoring user health factors.
   * Calculating collateral values.
   * Executing liquidations.
   * Integrating with Chainlink price feeds.
   * Enforcing protocol collateralization rules. </br>
   This contract is the only contract permitted to mint or burn DSC.
2. ****DecentralizedStableCoin:**** `DecentralizedStableCoin` is a standard ERC20 token that represents the protocol's stablecoin.</br>
  Its responsibilities are intentionally minimal: </br>
    * ERC20 transfers.
    * Minting.
    * Burning. </br>
  The contract does not contain collateral logic or price calculations. </br>
  Instead, ownership is transferred to the `DSCEngine`, ensuring DSC can only be minted when sufficient collateral exists.
3. ****OracleLib:**** `OracleLib` is a utility library responsible for interacting safely with Chainlink price feeds. </br>
  It provides: </br>
    * Stale price protection.
    * Secure oracle reads.
    * Standardized price retrieval. </br>
  By validating oracle freshness, the protocol avoids making decisions using outdated market prices.
4. ****Chainlink Price Feeds:**** The protocol relies on Chainlink decentralized oracles to determine the USD value of supported collateral assets. </br>
  Price data is used for: </br>
     * Collateral valuation.
     * Health factor calculation.
     * Minting limits.
     * Liquidation eligibility.
     * Collateral redemption. </br>
5. ****Supported Collateral:**** The protocol accepts only whitelisted collateral assets.  </br>
  Examples include: </br>
      * Wrapped Ether (WETH).
      * Wrapped Bitcoin (WBTC). </br>
  Each supported token has an associated Chainlink price feed configured during deployment. </br>


### Protocol Flow
```shell
User
 │
 │ Deposit WETH/WBTC
 ▼
DSCEngine
 │
 ├── Stores collateral
 ├── Calculates USD value
 ├── Checks Health Factor
 └── Mints DSC
       │
       ▼
DecentralizedStableCoin
       │
       ▼
User receives DSC
```
When a user repays debt: </br>
```shell
User
 │
 │ Burn DSC
 ▼
DSCEngine
 │
 ├── Reduces debt
 ├── Updates Health Factor
 └── Releases collateral
       │
       ▼
Collateral returned
```
If a user's collateral becomes insufficient: </br>
```shell
    Health Factor < 1
        │
        ▼
Liquidator repays DSC
        │
        ▼
Receives user's collateral
      + bonus
```



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
* ****Solidity**** : The programming language for writing the Smart contracts.
* ****Foundry**** : Development framework and testing suite.



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

 ⚠️ **Security Warning:**
  * Never commit your `.env` file.
  * Never use your mainnet private key for testing.
  * Use a separate wallet with only testnet funds.



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



## Gas Optimization 
The protocol is designed with gas efficiency in mind. The following optimization mechanisms are applied across the smart contracts to reduce deployment size, lower transaction costs, and improve execution performance without compromising security or maintainability.
* ****Custom Errors****: Replaces traditional revert strings with Solidity custom errors, significantly reducing deployment size and gas consumption whenever transactions revert while providing structured and descriptive error handling.
* ****Immutable Variables****: Stores the `DecentralizedStableCoin` contract address as an immutable variable, allowing the compiler to embed the value directly into the contract bytecode and eliminating expensive storage reads after deployment.
* ****Constant Variables****: Defines protocol configuration values such as precision, liquidation threshold, and liquidation bonus as constants, enabling compile-time substitution and removing the need for runtime storage access.
* ****Checks-Effects-Interactions (CEI) Pattern****: Updates the protocol's internal state before interacting with external contracts, reducing the risk of reentrancy attacks while avoiding unnecessary state rewrites caused by failed external calls.
* ****Reentrancy Protection****: Utilizes OpenZeppelin's `ReentrancyGuard` on critical functions to prevent nested contract calls from manipulating protocol state during execution, improving both security and transaction reliability.
* ****Internal Function Reuse****: Consolidates common logic into reusable internal helper functions such as `_burnDsc()`, `_redeemCollateral()`, `_healthFactor()`,and `_calculateHealthFactor()`, minimizing duplicated bytecode and lowering deployment costs.  
* ****Cached Storage Reads****: Reads frequently accessed storage values once into local variables before performing calculations, reducing repeated `SLOAD` operations and improving execution efficiency.


 
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
* ****Oracle Library Abstraction****: Centralizes Chainlink oracle interactions within `OracleLib`, preventing duplicated validation logic across the protocol while reducing contract size and improving maintainability.
* ****External Function Visibility****: Declares functions as `external` where appropriate, allowing Solidity to read function arguments

  


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
* Read the project documentation carefully before interacting with the protocol to understand its collateral requirements, minting process, redemption flow, liquidation mechanics, and operational assumptions.


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
