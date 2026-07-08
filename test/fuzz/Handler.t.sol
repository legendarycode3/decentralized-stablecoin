// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";


/**
 * @title  Handler Contract for Invariant/Fuzz Testing
 * @author LegendaryCode
 * @notice This contract handles and constrains actions passed to the Foundry invariant 
 *         fuzzer.
 * @dev It bounds random inputs to prevent the fuzzer from calling functions with invalid 
 *      states (e.g., minting without collateral).
 */
contract Handler is Test {

    /*////////////////////////////  //////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    /// @notice Tracks how many times the mintDsc function has been successfully executed.
    uint256 public timesMintIsCalled;

    /// @notice Array containing all user addresses that have deposited collateral into the system.
    address[] public usersWithCollateralDeposited; 

    MockV3Aggregator public ethUsdPriceFeed;

    /// @dev Sets the upper limit for collateral deposits to prevent overflow errors during fuzzing.
    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;



    /*////////////////////////////  //////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Initializes the handler with the core system contracts and extracts 
     *          collateral token information.
     * @param _dscEngine The address of the deployed DSCEngine contract.
     * @param _dsc The address of the deployed DecentralizedStableCoin contract.
     */
    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;
 
        // Dynamically fetch and store collateral token instances from the engine
        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

         // Dynamically fetch the Chainlink price feed for WETH
        ethUsdPriceFeed =  MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(weth)));
    }   



    /*////////////////////////////  //////////////////////////////////
                            FUZZING HANDLE ACTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Simulates users minting DSC based on random fuzz inputs.
     * @dev Selects a random user from existing depositors and calculates their safe maximum 
     *      minting capacity to avoid breaking the health factor. 
     * @param amount The fuzzed amount of DSC to mint.
     * @param addressSeed A random value used to pick a valid user from the 
     *        `usersWithCollateralDeposited` array.
    */
    function mintDsc(uint256 amount, uint256 addressSeed) public {

        // If no users have deposited collateral yet, minting is impossible. Skip the call.
        if(usersWithCollateralDeposited.length == 0) {
            return ;
        }

        // Use the address seed to pick a random, valid depositor from our tracking array.
        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length];
        
        // Fetch current position metrics for the selected user.
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(sender);

        // Check if the user is already at or above their 50% max loan-to-value ratio.
        if (collateralValueInUsd / 2 <= totalDscMinted) {
            return;
        }

        // Calculate the maximum remaining DSC this user can safely mint without liquidating themselves.
        uint256 maxDscToMint = (collateralValueInUsd / 2) - totalDscMinted;

        // Constrain the fuzzed amount to be between 1 and the user's safe maximum capacity.
        amount = bound(amount, 1, maxDscToMint);

        // Prank(Stimulate) the selected user address to execute the minting action in the DSCEngine.
        vm.startPrank(sender);
        dsce.mintDsc(amount);
        vm.stopPrank();

        // Log successful execution for invariant metrics.
        timesMintIsCalled++;
    }


    /**
     *  @notice Simulates users depositing collateral into the system.
     *  @dev This is a placeholder for your deposit collateral logic.
    */
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        // dsce.depositCollateral(collateral, amountCollateral);

        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);

        dsce.depositCollateral(address(collateral), amountCollateral);

        vm.stopPrank();

        usersWithCollateralDeposited.push(msg.sender);
    }


    /**
     * @notice Redeems a bounded amount of collateral from the DSCEngine using a random seed.
     *  @dev Maps a collateral seed to an ERC20 token, checks the maximum balance the sender 
     *       can redeem. 
     * @dev Restricts the redemption amount to valid bounds to prevent fuzz testing         
     *      underflow/overflow reverts.
     * @param collateralSeed The random seed used to select which ERC20 collateral to redeem.
     * @param amountCollateral The unconstrained, randomly fuzzed amount of collateral to 
     *        redeem.
     * @custom:invariant The protocol requires that the total value of collateral is greater 
     *      than the DSC total supply.
     */
    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {

        ERC20Mock collateral  = _getCollateralFromSeed(collateralSeed);
        uint256  maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(address(collateral), msg.sender);
        amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);
        if(amountCollateral == 0){
            return;
        }

        dsce.redeemCollateral(address(collateral), amountCollateral);
    }



    // Helper Functions
    /**
     * @notice Derives a collateral token based on the provided numerical seed
     * @dev Uses the modulo operator to pseudo-randomly pick between Wrapped Ether (WETH) and Wrapped Bitcoin (WBTC)
     * @param collateralSeed A random or arbitrary number used to determine the collateral type
     * @return Returns the ERC20Mock contract address of the selected collateral
    */
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock) {
         // If the seed is even, select WETH; if odd, select WBTC
        if(collateralSeed % 2 == 0){
            return weth;
        }
        return wbtc;
    }
}