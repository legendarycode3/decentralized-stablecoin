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

 
## Security Considerations
* ****Reentrancy Protection:**** The protocol uses OpenZeppelin's `ReentrancyGuard` to protect functions that transfer collateral or perform state-changing operations involving external token contracts. By preventing nested calls into sensitive functions such as collateral deposits, redemptions, minting, and liquidations, the protocol mitigates classic reentrancy attacks that could otherwise manipulate internal accounting or drain collateral. 
* ****Checks-Effects-Interactions (CEI) Pattern:**** The protocol consistently follows the Checks-Effects-Interactions pattern. Internal state variables are updated before interacting ensuring that malicious external contracts cannot exploit intermediate states during execution. This design significantly reduces the attack surface for reentrancy and maintains consistent protocol accounting.
* ****Oracle Security:**** Collateral valuations rely on Chainlink price feeds with additional stale-price validation through `OracleLib`. Rather than directly consuming the latest oracle response, the protocol verifies that price data is sufficiently recent before using it in collateral calculations. This helps protect the protocol against stale oracle data that could otherwise lead to incorrect collateral valuations, unsafe minting, or unfair liquidations.
* ****Collateral Whitelisting:**** Only explicitly approved collateral assets can be deposited into the protocol. Every collateral token must have an associated trusted price feed configured during deployment, preventing users from depositing unsupported or malicious ERC-20 tokens whose values cannot be safely verified.
* ****Health Factor Enforcement:**** Every operation capable of increasing protocol risk, including minting, collateral redemption, and liquidation is protected by health factor validation. Users cannot create or maintain positions that fall below the minimum collateralization threshold, ensuring the protocol remains fully overcollateralized and reducing the likelihood of bad debt.
* ****Overcollateralization Requirement:**** The stablecoin is fully backed by excess collateral rather than relying on algorithmic stabilization mechanisms. Users must maintain collateral whose value exceeds their outstanding debt according to the configured liquidation threshold,
 
*
*
* with external ERC-20 token contracts,
