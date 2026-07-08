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
* **OpenZeppelin Security:** Built on audited OpenZeppelin ERC20 and access
 
