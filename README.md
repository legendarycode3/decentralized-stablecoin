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
### Introduction
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

### Contract Relationships 
```shell
                      +---------------------------+
                    |   Chainlink Price Feeds   |
                    +-------------+-------------+
                                  |
                                  |
                         Reads Market Prices
                                  |
                                  ▼
                    +---------------------------+
                    |       OracleLib.sol       |
                    +-------------+-------------+
                                  |
                                  ▼
+-----------------------------------------------------------+
|                    DSCEngine.sol                          |
|-----------------------------------------------------------|
| • Collateral Management                                  |
| • Mint & Burn DSC                                        |
| • Health Factor Calculations                             |
| • Liquidation Engine                                     |
| • Protocol Accounting                                    |
+------------------------+----------------------------------+
                         |
                         | Controls Minting & Burning
                         ▼
          +-------------------------------+
          | DecentralizedStableCoin.sol   |
          |        (ERC-20 Token)         |
          +-------------------------------+
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



## Smart Contracts
The Decentralized Stablecoin protocol follows a modular architecture in which each smart contract is responsible for a specific aspect of the system.  This separation of concerns improves security, maintainability, and extensibility while keeping the protocol architecture clean and easy to understand.

### `DSCEngine.sol`
 The `DSCEngine` contract is the core of the protocol and manages all collateralized debt positions (CDPs).  It handles collateral deposits, stablecoin minting and burning, collateral redemption, liquidation, health factor calculations, and protocol accounting. The contract integrates Chainlink Price Feeds to determine the USD value of supported collateral assets and ensures every minted DSC remains safely overcollateralized.

#### Responsibilities
* Accepts approved collateral assets.
* Mints DSC against deposited collateral.
* Burns DSC during debt repayment.
* Redeems collateral after health factor validation.
* Calculates user health factors.
* Processes liquidations for undercollateralized positions.
* Tracks protocol collateral and user debt.

### `DecentralizedStableCoin.sol` 
The DecentralizedStableCoin contract implements the ERC-20 stablecoin used throughout the protocol. It is intentionally lightweight and delegates all collateral management and protocol logic to the `DSCEngine`. Minting and burning are restricted to the protocol owner (the `DSCEngine`), ensuring that DSC can only be created or destroyed through the protocol's collateralization rules.

#### Responsibilities
* Implements the ERC-20 token standard.
* Mints new DSC tokens.
* Burns existing DSC tokens.
* Restricts token issuance to the protocol.
* Maintains the total token supply.

### `OracleLib.sol`
The `OracleLib` library provides a safe abstraction for interacting with Chainlink Price Feeds. It validates oracle responses by checking for stale price data before allowing prices to be used in protocol calculations, helping protect the system from outdated market information.

#### Responsibilities
* Reads Chainlink price data.
* Validates oracle freshness.
* Prevents stale price usage.
* Standardizes oracle interactions across the protocol.



## Functions
The Decentralized Stablecoin protocol exposes a set of public and external functions through the `DSCEngine` and `DecentralizedStableCoin` contracts. These functions are grouped by responsibility to provide a clear understanding of the protocol’s capabilities and how users interact with the system.

### DSCEngine Functions
The `DSCEngine` contract contains the core protocol logic for collateral management, stablecoin operations, liquidations, and account information retrieval.

#### Collateral Management
* `depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)`: Deposits an approved collateral asset into the protocol. The deposited collateral is securely recorded in the user’s account and contributes to the user’s borrowing capacity for minting DSC.
* `redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)`: Withdraws deposited collateral from the protocol, provided the user’s health factor remains above the minimum required threshold after the withdrawal, ensuring the protocol remains safely collateralized.
* `depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToMint)`: Combines collateral deposit and DSC minting into a single atomic transaction, improving user experience by reducing the number of required interactions with the protocol.
* `redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn)`: Burns DSC and redeems collateral in a single transaction, allowing users to efficiently repay debt and withdraw their collateral in one seamless operation.

#### Stablecoin Operations
* `mintDsc(uint256 amountDscToMint)`: Mints new DSC tokens against the user’s deposited collateral after verifying that the user’s health factor remains above the minimum threshold required by the protocol.
* `burnDsc(uint256 amount)`: Burns DSC tokens from the user’s balance, reducing the user’s outstanding debt and improving their health factor within the protocol.
* `Liquidation(address collateral, address user, uint256 debtToCover)`: Allows a third party to liquidate an undercollateralized position by repaying a portion of the user’s DSC debt in exchange for the corresponding collateral plus a liquidation bonus.

#### Account Information
* `getAccountInformation(address user)`: Returns the total DSC minted by a user and the total USD value of their deposited collateral, providing a complete overview of the user’s protocol position.
* `getHealthFactor(address user)`: Returns the current health factor of a user, indicating whether their position is safely collateralized or at risk of liquidation.
* `getAccountCollateralValue(address user)`: Returns the total USD value of all collateral deposited by a user across all supported collateral assets.
* `getCollateralBalanceOfUser(address user, address token)`: Returns the amount of a specific collateral token deposited by a user within the protocol.

#### Price and Conversion Utilities
* `getUsdValue(address token, uint256 amount)`: Converts a token amount into its equivalent USD value using Chainlink price feeds, ensuring accurate collateral valuation.
* `getTokenAmountFromUsd(address token, uint256 usdAmountInWei)`: Converts a USD value into the equivalent amount of a supported collateral token based on current oracle pricing.
* `calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsd)`: Calculates the health factor for a position based on its minted DSC and collateral value, helping determine whether the position is safely collateralized.

#### Protocol Configuration
* `getCollateralTokens()`: Returns the list of approved collateral tokens supported by the protocol.
* `getPriceFeed(address token)`: Returns the Chainlink price feed address associated with a supported collateral token.
* `getCollateralTokenPriceFeed(address token)`: Returns the configured price feed address for a specific collateral token.
* `getDscAddress()`: Returns the address of the deployed 'DecentralizedStableCoin' contract.

### DecentralizedStableCoin Functions
The `DecentralizedStableCoin` contract implements the ERC-20 stablecoin and exposes only the protocol-specific functions.

#### Token Operations
* `mint(address _to, uint256 _amount)`: Mints new DSC tokens to a specified address. This function can only be called by the contract owner (`DSCEngine`) and is used when users mint DSC against deposited collateral.
* `burn(uint256 _amount)`: Burns a specified amount of DSC tokens from the owner’s balance. This function can only be called by the `DSCEngine` and is used when users repay debt by burning DSC.
 


## How It Works
The Decentralized Stablecoin (DSC) protocol allows users to deposit approved cryptocurrency collateral and mint a USD-pegged stablecoin while maintaining protocol solvency through overcollateralization and automated liquidations. 

### Protocol Workflow
The protocol follows a simple but secure workflow that ensures every DSC token is backed by sufficient collateral.

```shell
   User Deposits Collateral (WETH / WBTC)
                │
                ▼
     DSCEngine Stores Collateral
                │
                ▼
  Chainlink Price Feeds Determine USD Value
                │
                ▼
      Health Factor Is Calculated
                │
                ▼
  If Health Factor Is Safe, DSC Is Minted
                │
                ▼
        User Receives DSC
```
### Step-by-Step Process
#### 1. Deposit Collateral:
A user begins by depositing an approved collateral asset, such as WETH or WBTC, into the `DSCEngine` contract. The protocol records the deposited amount in the user’s account and uses it as the basis for determining the user’s borrowing capacity.

#### 2. Collateral Valuation: 
Once collateral is deposited, the protocol retrieves real-time USD prices from Chainlink Price Feeds. These prices are used to calculate the total USD value of the user’s collateral and determine how much DSC can be safely minted.

#### 3. Health Factor Calculation:
Before minting DSC, the protocol calculates the user’s `Health Factor`, which represents the safety of the collateralized position.
 


## Technology Stack (Technologies Used)
* ****Solidity**** : The programming language for writing the Smart contracts.
* ****Foundry**** : Development framework and testing suite.



## Getting Started
### Prerequisites
Ensure the following tools are installed on your machine: </br>
* [FOUNDRY](https://www.getfoundry.sh/introduction/installation) - Ethereum development toolchain
    * Verify installation: `forge --version`
* [GIT](https://git-scm.com/) - - Version control
     * Verify installation: `git --version`
* ****[Solidity](https://www.soliditylang.org/)**** - Solidity ^0.8.18
       

### Installation
 1. Clone the repository:
    ```shell
        git clone https://github.com/legendarycode3/decentralized-stablecoin
    ```
    Navigate into the project directory:
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
      PRIVATE_KEY=your_private_key
      SEPOLIA_RPC_URL=your_sepolia_rpc_url
      ETHERSCAN_SEPOLIA_API_KEY=your_etherscan_api_key
   ```
2. ****Get testnet ETH:**** </br>
      * ETH Sepolia Faucet: [Eth Sepolia Faucet](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)


⚠️ **Security Warning:**
* Never commit your `.env` file.
* Never use your mainnet private key for testing.
* Use a separate wallet with only testnet funds.

### Deployment
Deploy the Decentralized Stablecoin protocol to the configured blockchain network using the project's Makefile.

### Deploy the Protocol
```shell
  make deploy
```


## Usage
The Decentralized Stablecoin protocol enables users to interact with the system by depositing collateral, minting DSC, repaying debt, redeeming collateral, and liquidating undercollateralized positions. All protocol interactions are executed through the DSCEngine smart contract. 

### Deposit Collateral
Users can deposit approved collateral assets (e.g., WETH or WBTC) into the protocol after granting the DSCEngine contract permission to spend their tokens.
```shell
  User
   │
Approve Collateral
   │
   ▼
Deposit Collateral
   │
   ▼
DSCEngine
```
### Mint DSC 
Once sufficient collateral has been deposited, users can mint Decentralized Stablecoin (DSC). The protocol validates the user's health factor before minting to ensure the new debt remains safely collateralized.
```shell
  Deposit Collateral
        │
        ▼
Health Factor Check
        │
        ▼
Mint DSC
        │
        ▼
User Receives DSC
```
### Deposit and Mint in a Single Transaction
For convenience, users can deposit collateral and mint DSC atomically using the `depositCollateralAndMintDsc()` function. This combines both operations into a single transaction, reducing user interaction and gas overhead.

### Burn DSC
Users may burn DSC at any time to reduce or completely repay their outstanding debt. Burning DSC improves the user's health factor and decreases the amount of debt secured by their collateral.

### Redeem Collateral
After reducing or repaying their debt, users can redeem part or all of their deposited collateral. Before releasing collateral, the protocol verifies that the account remains above the minimum health factor. 
```shell
  Burn DSC
    │
    ▼
Redeem Collateral
    │
    ▼
Collateral Returned
```

### Redeem Collateral and Burn DSC
The protocol also provides an atomic operation that burns DSC and redeems collateral within a single transaction, simplifying the repayment process while maintaining protocol safety.

### Liquidate Unsafe Positions
If a user's health factor falls below the required minimum collateralization threshold, anyone may liquidate part of the position by repaying a portion of the user's DSC debt. </br>
In return, the liquidator receives the corresponding collateral plus a liquidation bonus as an incentive.
```shell
  Health Factor < Minimum
          │
          ▼
Liquidator Burns DSC
          │
          ▼
Receives Collateral + Bonus
```


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
 │   └── HelperConfig.s.sol                                           # Network-specific configuration (price feeds, collateral tokens, etc.)
 ├── src                                                              # Smart contract source code
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
 ├── Makefile                                                         # Build, test, deployment, and  utility commands.
 └── README.md                                                        # Project documentation.
```



## Gas Optimization 
The protocol is designed with gas efficiency in mind. The following optimization mechanisms are applied across the smart contracts to reduce deployment size, lower transaction costs, and improve execution performance without compromising security or maintainability.
* ****Custom Errors****: Replaces traditional revert strings with Solidity custom errors, significantly reducing deployment size and gas consumption whenever transactions revert while providing structured and descriptive error handling.
* ****Immutable Variables****: Stores the `DecentralizedStableCoin` contract address as an immutable variable, allowing the compiler to embed the value directly into the contract bytecode and eliminating expensive storage reads after deployment.
* ****Constant Variables****: Defines protocol configuration values such as precision, liquidation threshold, and liquidation bonus as constants, enabling compile-time substitution and removing the need for runtime storage access.
* ****Internal Function Reuse****: Consolidates common logic into reusable internal helper functions such as `_burnDsc()`, `_redeemCollateral()`, `_healthFactor()`,and `_calculateHealthFactor()`, minimizing duplicated bytecode and lowering deployment costs.  
* ****Cached Storage Reads****: Reads frequently accessed storage values once into local variables before performing calculations, reducing repeated `SLOAD` operations and improving execution efficiency.
* ****Oracle Library Abstraction****: Centralizes Chainlink oracle interactions within `OracleLib`, preventing duplicated validation logic across the protocol while reducing contract size and improving maintainability.
* ****External Function Visibility****: Declares functions as `external` where appropriate, allowing Solidity to read function arguments directly from calldata instead of copying them into memory, resulting in lower gas costs for external calls.
* ****Event-Based Activity Tracking****: Records protocol activities such as collateral deposits and collateral redemptions through events instead of additional storage variables, providing transparent on-chain logs with significantly lower gas costs.


 
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
* ****Precision-Safe Arithmetic:**** The protocol performs all financial calculations using fixed-point arithmetic with, standardized precision constants. This avoids floating-point inaccuracies while minimizing rounding errors during collateral valuation, health factor calculations, and liquidation logic.


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
