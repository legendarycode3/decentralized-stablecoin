// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";



/**
 * @title  Decentralized StableCoin DeployDSC Script
 * @author LegendaryCode
 * @notice This script automates the deployment of the DSC and DSCEngine contracts
 * @dev Inherits from Forge's Script contract to manage EVM deployment pipelines
 */
contract DeployDSC is Script {
   
   /// @notice Dynamic array tracking allowed collateral ERC20 token addresses
   address[] public tokenAddresses;

   /// @notice Dynamic array tracking Chainlink USD price feeds for the collateral tokens
   address[] public priceFeedAddresses;

   /// @dev State variable storing the initial sender address (primarily for testing purposes)
   address initialOwner = msg.sender;


   /**
    * @notice Executes the deployment sequence for the DSC ecosystem.
    * @dev Loads network configuration, deploys contracts, and transfers DSC ownership to 
    *      the engine.
    * @return dsc The deployed DecentralizedStableCoin contract instance.
    * @return engine The deployed DSCEngine contract instance.
    * @return config The deployed HelperConfig contract instance.
    */
   function run() external returns(DecentralizedStableCoin, DSCEngine, HelperConfig){

         // Initialize network configuration helper
        HelperConfig config = new HelperConfig();
        
        // Unpack specific network parameters from the active configuration
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) = config.activeNetworkConfig();
        
        // Group collateral assets and price feeds into arrays for engine initialization
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        // Derive the actual deployer address from the private key
        address deployer = vm.addr(deployerKey);

        // Instruct Forge to broadcast all subsequent deployment transactions to the RPC network
        vm.startBroadcast(deployerKey);
       
        // Deploy the stablecoin ERC20 contract with the deployer as its initial temporary owner
        DecentralizedStableCoin dsc = new DecentralizedStableCoin(deployer);

         // Deploy the core logic engine, passing collateral types, price feeds, and the DSC address
        DSCEngine engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

         // Transfer exclusive minting and burning control over DSC to the DSCEngine contract
        dsc.transferOwnership(address(engine));

        // Stop recording transactions for the network broadcast
        vm.stopBroadcast();

         // Return instances to enable seamless handoffs to testing suites or scripts
        return (dsc, engine, config);
   }
   
}