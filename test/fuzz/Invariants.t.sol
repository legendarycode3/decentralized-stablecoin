// SPDX-License-Identifier: MIT



pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Handler} from "./Handler.t.sol";



/**
 * @title  Invariants Test Suite for the Stable Coin (DSC) Protocol
 * @author LegendaryCode
 * @notice This contract handles stateful fuzzing (invariant tests) to ensure core protocol 
 *         truths always hold.
 * @dev Inherits from Forge Standard Test and StdInvariant to enable invariant configuration.
 */
contract Invariants is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config; 
    address weth;
    address wbtc;

    Handler handler;


    /**
     * @notice Sets up the testing environment, deploys contracts, and registers the 
     *         conditional fuzzing handler.
     * @dev This function is called once before any invariant tests are executed (Runs 
     *      automatically).
     */
    function setUp() external {

        // Initialize deployment scripts and unpack system architecture
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();

        // Instantiate the handler to manage valid action sequences during fuzzing
        handler = new Handler(dsce, dsc);

        // Direct the fuzzer to call functions on the handler instead of random protocol methods
        targetContract(address(handler));
    }


    /**
     * @notice Invariant: The total USD value of protocol collateral must always be greater 
     *         than or equal to the total DSC supply.
     * @dev This ensures the system remains fully or over-collateralized at all times under 
     *      any transaction sequence.
    */
    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        // Fetch global supply metrics
        uint256 totalSupply = dsc.totalSupply();

        // Fetch raw token balances held securely inside the engine
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalBtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        // Convert the underlying token assets into their equivalent USD valuations
        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalBtcDeposited);

        // Log performance metrics for debugging when invariant checks trigger or fail
        console.log("weth value:", wethValue );
        console.log("wbtc value:", wbtcValue );
        console.log("total supply:", totalSupply);
        console.log("Times mint called: ", handler.timesMintIsCalled());

        // Core systemic check: Total Collateral USD Value >= Total Debt Issued
        assert(wethValue + wbtcValue >= totalSupply); 
    }


    /**
     * @notice Invariant: System configuration getter functions must remain open and never 
     *         revert.
     * @dev Ensures external UI interfaces and secondary protocols can safely read 
     *      configuration constants.
     */
    function invariant_gettersShouldNotRevert() public view {
        dsce.getLiquidationBonus();
        dsce.getPrecision();
    }


}