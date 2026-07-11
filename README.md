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



## Project Structure
```shell 
 ├── script                           # Deployment and
 │   ├── DeployDSC.s.sol
 │   └── HelperConfig.s.sol   
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

### Audit Status
****⚠️ NOT AUDITED**** - Do not deploy to mainnet or use with real funds without professional security audit.



## Known Risks & Assumptions
* ****Oracle Dependency:**** The protocol depends on external Chainlink price feeds for collateral valuation. Although stale price checks reduce oracle-related risks, prolonged oracle outages, delayed updates, or unexpected oracle failures could temporarily affect collateral valuation and liquidation functionality. The protocol assumes trusted oracle infrastructure remains available and operational.
* ****Fee-on-Transfer Token Compatibility:**** The protocol assumes supported collateral tokens transfer the exact amount requested during deposits and withdrawals. Fee-on-transfer, rebasing, or deflationary ERC-20 tokens may result in discrepancies between recorded collateral balances and actual token balances held by the protocol. Only standard ERC-20 collateral assets should be supported unless additional accounting logic is implemented.
* ****Extreme Market Conditions:**** The liquidation mechanism assumes collateral maintains sufficient value to incentivize liquidators. During severe market crashes where collateral value falls below outstanding debt, liquidations may become economically unattractive, potentially resulting in protocol bad debt. This limitation is common among overcollateralized lending protocols and should be considered when selecting supported collateral assets and liquidation parameters.
* ****Oracle Decimal Assumptions:**** The protocol assumes supported Chainlink price feeds use the expected decimal precision during price normalization. Introducing price feeds with different decimal configurations without adjusting precision calculations may result in inaccurate collateral valuations. Future protocol upgrades should normalize oracle decimals dynamically where appropriate.
* ****No Emergency Pause Mechanism:**** The protocol intentionally operates without an emergency pause or circuit breaker. While this increases decentralization by eliminating privileged administrative intervention, it also means protocol operations cannot be temporarily suspended in the event of unexpected vulnerabilities, oracle failures, or ecosystem-wide incidents.
* ****Governance Assumptions:**** The current implementation assumes the set of supported collateral assets and their associated price feeds remain fixed after deployment. Since no governance mechanism exists to modify protocol parameters, any future changes would require deploying a new version of the protocol. This immutable design minimizes governance risk but reduces operational flexibility.
* ****User Responsibility:**** Users remain responsible for monitoring their own health factor and maintaining sufficient collateralization. Significant market volatility may rapidly reduce collateral value, causing positions to become eligible for liquidation. The protocol does not automatically rebalance user positions or provide protection against liquidation resulting from market movements.



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
