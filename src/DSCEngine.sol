// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./libraries/OracleLib.sol";


/**
 * @title  DSCEngine
 * @author LegendaryCode
 * 
 * @notice This contract is the core of the DSC System. It handles all the logic for 
 *         minting and redeeming DSC, as well as depositing and withdrawing collateral.
 *         This contract is VERY  loosely based on the MakerDAO DSS (DAI) system.
 */

contract DSCEngine is ReentrancyGuard {

    /*//////////////////////////////////////////////////////////////
                              ERRORS 
    //////////////////////////////////////////////////////////////*/
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();



    /*//////////////////////////////////////////////////////////////
                              TYPE
    //////////////////////////////////////////////////////////////*/
    using OracleLib for AggregatorV3Interface;



    /*//////////////////////////////////////////////////////////////
                              STATE VARIABLES 
    //////////////////////////////////////////////////////////////*/    
    /**
     * @notice Scales price feeds to maintain standard decimal precision.
     * @dev Chainlink USD price feeds typically return data with 8 decimal places. 
     * This constant multiplies 8-decimal data by $10^{10}$ to convert it to 18-decimal
     * (Wei) precision. This standardization prevents precision loss and rounding 
     * errors when executing math calculations (e.g., USD to token conversions).
    */
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;


    /**
     * @dev The scaling factor used to represent 1.0 in fixed-point decimal arithmetic
        Solidity does not support floating-point numbers, so all math operations that require fractional values are scaled by this factor (1e18).
     */
    uint256 private constant PRECISION = 1e18;


    /**
     * @notice Defines the maximum allowable Loan-to-Value (LTV) percentage.
     * @dev A value of 50 represents 50%. If the user's debt exceeds 50% 
     * of their deposited collateral value, the protocol's liquidation engine 
     * is triggered. Set as 'constant' to save deployment and execution gas costs.
     */
    uint256 private constant LIQUIDATION_THRESHOLD = 50; 


    /**
     *  @notice Precision factor used for liquidation and percentage-based calculations. *      This constant acts as the denominator for fractional percentage calculations.
     *  @dev The precision scale used for liquidation math (represents 100%).
     *      Used to convert ratios into human-readable percentages and enforce consistent
     *      liquidation math across the protocol.
    */
    uint256 private constant LIQUIDATION_PRECISION = 100;


    /**
     * @notice The minimum health factor a user's position must maintain.
     * @dev This is represented with 18 decimal precision ($10^{18}$). 
     *      If a position's health factor drops below this value, the position becomes 
     *      undercollateralized and eligible for liquidation.
    */
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;


    /**
     * @dev Additional bonus given to the liquidator on top of the repaid debt. 
     * Represented as a percentage (i.e., 10 means 10%).
    */
    uint256 private constant LIQUIDATION_BONUS = 10;


    /**
     * @dev Maps a token's contract address to its corresponding oracle price feed.
     *      This allows the contract to dynamically resolve price data for different assets.
     *      The key is the token's address, and the value is the AggregatorV3Interface      address.
    */
    mapping(address token => address priceFeed) private s_priceFeeds;


    /**
     * @dev Tracks the collateral balances of users within the protocol.
     * @notice Maps a user's address to a token address, and then to the deposited amount.
     * @dev The nesting structure is `[userAddress][tokenAddress] => amount`.
    */
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited; 


    /**
     * @notice Tracks the total amount of DSC minted by a specific user.
     * @dev Maps an Ethereum address to a uint256 representing the minted DSC balance.
     *      This variable is kept private to prevent direct external modification 
     *      and enforce accounting integrity within the contract.
    */
    mapping (address user => uint256 amountDscMinted) private s_DSCMinted;


    /**
     * @dev Dynamic array storing the Ethereum addresses of all authorized collateral tokens.
     *      These are used across the protocol to calculate system health, manage 
     *      deposits, and process liquidations.
    */
    address[] private s_collateralTokens;


    /**
     * @notice Reference to the Decentralized Stablecoin contract
     * @dev The `private` visibility prevents this variable from being accessed or 
     *      viewed directly outside of this contract. 
     *      The `immutable` keyword means the value can only be set once during 
     *      the constructor execution and cannot be changed afterward.
    */
    DecentralizedStableCoin private immutable i_dsc;    



    /*//////////////////////////////////////////////////////////////
                              EVENTS 
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when a user deposits a token as collateral into the smart contract.
     * @param user The address of the user making the collateral deposit.
     * @param token The address of the token being deposited as collateral.
     * @param amount The quantity of the token being deposited.
    */
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);


    /**
     *  @notice Emitted when collateral is redeemed from the protocol.
     *  @param redeemedFrom The address whose collateral was taken/redeemed.
     *  @param redeemedTo The address receiving the redeemed collateral.
     *  @param token The address of the collateral token being redeemed.
     *  @param amount The quantity of tokens being redeemed.
     */
    event CollateralRedeemed(address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256  amount );



    /*//////////////////////////////////////////////////////////////
                              MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    /**
    * @notice Ensures a value is greater than zero.
    * @dev Reverts if the provided amount is zero.
    * @param amount The uint256 value to be checked.
    */
    modifier moreThanZero(uint256 amount) {
        if(amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }


    /**
    * @notice Validates that a token is allowed by checking its price feed.
    * @dev Reverts with `DSCEngine__NotAllowed` if the price feed address is `address(0)`.
    * @param token The address of the ERC20 token being validated.
    */
    modifier isAllowedToken(address token) {
        if(s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }
   


    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the DSCEngine contract with supported collateral tokens, their Chainlink price feeds, and the DSC stablecoin address.
     * @dev Ensures that the token addresses and price feeds arrays match in length before updating state variables.
     * 
     *  @param tokenAddresses An array containing the addresses of the supported collateral tokens.
     * @param priceFeedAddresses An array containing the corresponding Chainlink price feed addresses for each token.
     * @param dscAddress The contract address of the DecentralizedStableCoin (DSC) deployment.
    */ 
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress)  {
        
        // Revert transaction if the inputs do not have a 1:1 mapping mapping
        if(tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        // Loop through the input arrays to populate state storage
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            // Map each collateral token address to its designated oracle price feed
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];

            // Track the allowed collateral token by adding it to the list
            s_collateralTokens.push(tokenAddresses[i]);
        }

        // Instantiate and store the immutable DecentralizedStableCoin contract interface
        i_dsc = DecentralizedStableCoin(dscAddress);
    }



    /*//////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Combines the deposit of collateral and the minting of DSC into a single atomic transaction.
     * @dev This function assumes the user has already approved the contract to spend their collateral tokens.
     * @param tokenCollateralAddress The ERC20 contract address of the collateral being deposited.
     * @param amountCollateral The amount of collateral tokens the user wishes to deposit.
     * @param amountDscToMint The amount of Decentralized USD (DSC) the user wishes to mint.
    */
    function depositCollateralAndMintDsc(address tokenCollateralAddress,  uint256 amountCollateral, uint256 amountDscToMint) external {
        // Transfer collateral tokens from the user's wallet to this smart contract
        depositCollateral(tokenCollateralAddress, amountCollateral);

        //  Mint the specified amount of DSC stablecoins and assign them to the user
        mintDsc(amountDscToMint);
    }


    /**
     * @notice Deposits collateral into the Decentralized Stablecoin (DSC) Engine.
     * @dev Follows the Checks-Effects-Interactions pattern and uses OpenZeppelin ReentrancyGuard.
     * @dev Updates internal collateral accounting and transfers tokens from the caller.
     * 
     * @param tokenCollateralAddress The address of the token to deposit as collateral.(e.g WETH, WBTC)
     * @param amountCollateral The amount of collateral token to deposit.
     * 
     * @custom:modifier moreThanZero(amountCollateral) Ensures the deposited amount is valid.
     * @custom:modifier isAllowedToken(tokenCollateralAddress) Ensures the token is whitelisted.
     * @custom:modifier nonReentrant Prevents reentrancy exploits.
    */ 
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) isAllowedToken( tokenCollateralAddress) nonReentrant {

        // Updates the protocol's internal mapping to record the user's new collateral balance.
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;

        // Emits an event to the blockchain logs, allowing frontend apps to track the deposit.
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral );

        // Executes the ERC-20 transferFrom function to pull the collateral tokens from the user 
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this), amountCollateral);

        // Verifies if the token transfer was successful at the ERC20 contract level.
        if(!success) {
            revert DSCEngine__TransferFailed();
        }
    }


    /**
     * @notice Burns Decentralized Stablecoins (DSC) and redeems the corresponding
     *         collateral in a single transaction.
     * @dev Combines burning DSC and withdrawing collateral atomically to maintain the user's health factor.
     * @param tokenCollateralAddress  The address of the collateral token to redeem (e.g., *        WETH, WBTC).
     * @param amountCollateral  The amount of collateral tokens to redeem.
     * @param amountDscToBurn   The amount of DSC tokens to burn in exchange for the
     *        collateral in order to reduce debt.
    */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn) 
        external 
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress) {
        
        // Burn the specified amount of DSC from the user's balance
        burnDsc(amountDscToBurn);

        //  Withdraw the collateral from the protocol and transfer it to the user
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) public 
        moreThanZero(amountCollateral) 
        nonReentrant   
        isAllowedToken(tokenCollateralAddress) {

        // Transfer the collateral tokens from the contract's vault to the user's address (msg.sender)
       _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral );

        // Check if the user's health factor is compromised due to this collateral withdrawal.
        _revertIfHealthFactorIsBroken(msg.sender);
    }


    /**
     * @notice Follows CEI pattern
     * @notice Mints a specific amount of DSC to the caller's address.
     * @notice They must have more collateral value than the minimum threshold
     * @dev Updates the user's minted debt record and enforces health factor rules to ensure solvency.
     * 
     * @param amountDscToMint The amount of decentralized stablecoin to mint
     * 
     * @custom:modifier moreThanZero Reverts if the requested mint amount is zero or negative.
     * @custom:modifier nonReentrant Prevents reentrancy attacks by locking the function during execution.
    */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant  {
        // Record the new amount of DSC minted by the user
        s_DSCMinted[msg.sender] += amountDscToMint;

        // Checks if the user has sufficient collateral backing the new debt
        _revertIfHealthFactorIsBroken(msg.sender);

        // Call the DSC contract to mint the tokens to the user
        bool minted  = i_dsc.mint(msg.sender, amountDscToMint);

        // Ensure the external minting call succeeded
        if(!minted) {
            revert DSCEngine__MintFailed();
        }
    }
     

    /**
     * @notice Burns a specified amount of Decentralized Stablecoin (DSC) from the caller,
     *         to reduce the caller's outstanding debt.
     * @dev Updates the caller's minted DSC balance, transfers the DSC tokens from
     *      the caller to the protocol, permanently removes them from circulation,
     *      and verifies that the caller's account remains in a valid state
     * @param amount  The amount of DSC to burn. 
     */
    function burnDsc(uint256 amount) public moreThanZero(amount) {
        // Internal helper to pull and burn the DSC tokens from the user's balance
        _burnDsc(amount, msg.sender, msg.sender);

        // Reverts the transaction if the burn drops the user below the minimum collateralization threshold
        _revertIfHealthFactorIsBroken(msg.sender);
    }


    /**
     * @notice Liquidates a user who has broken the Minimum Health Factor requirement.
     * @dev Allows liquidators to partially pay off the user's debt and claim their 
     *      collateral as an incentive.
     * @dev Assumes the protocol maintains roughly 200% overcollateralization. A known bug 
     *      occurs if the collateralization ratio drops to <= 100%, as liquidators will no 
     *      longer be properly incentivized.
     * @param collateral The ERC-20 address of the collateral to be seized from the user.
     * @param user The address of the user whose health factor is below MIN_HEALTH_FACTOR.
     * @param debtToCover The amount of DSC the liquidator wishes to burn to improve the 
     *        user's health factor.
    */
    function liquidate(address collateral, address user, uint256 debtToCover) external moreThanZero(debtToCover) nonReentrant isAllowedToken(collateral) {

        // Fetch the user's current health factor before liquidation (Check if the user's health factor is truly broken)
        uint256 startingUserHealthFactor = _healthFactor(user);

        if(startingUserHealthFactor >= MIN_HEALTH_FACTOR){
            revert DSCEngine__HealthFactorOk();
        }

        // Calculate the exact amount of collateral tokens to be seized for the provided DSC debt
        uint256 tokenAmountFromDebtCovered  = getTokenAmountFromUsd(collateral, debtToCover);

        // Calculate the liquidation bonus (e.g., 10%) as extra collateral for the liquidator's incentive
        uint256 bonusCollateral  = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;

        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;

        // Transfer the seized collateral (debt + bonus) from the user to the liquidator
        _redeemCollateral(user, msg.sender,collateral, totalCollateralToRedeem);

        // Burn the debtToCover amount of DSC from the liquidator and credit it to the user
        _burnDsc(debtToCover, user, msg.sender);

        //  Verify that the user's health factor has actually improved after the transaction
        uint256 endingUserHealthFactor = _healthFactor(user);
        if(endingUserHealthFactor <= startingUserHealthFactor){
            revert DSCEngine__HealthFactorNotImproved();
        }

        // Ensure that the liquidator's own health factor is not broken by this action
        _revertIfHealthFactorIsBroken(msg.sender);
    }


    function getHealthFactor() external view {

    }


    
    /*//////////////////////////////////////////////////////////////
                              PRIVATE & INTERNAL FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Low-level internal function to burn DSC and handle accounting.
     * @dev This function should only be called by the DSCEngine itself. It assumes 
     *      the caller has already checked health factors and allowance.
     * @param amountDscToBurn The amount of DSC tokens to be burned.
     * @param onBehalfOf The address whose DSC debt is being reduced.
     * @param dscFrom The address from which the DSC tokens will be transferred.
     */
    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        // Update the accounting by reducing the DSC minted balance of the user
        s_DSCMinted[onBehalfOf] -= amountDscToBurn; 

        //  Transfer DSC from the specified user to the DSCEngine contract
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);

        //  Revert if the ERC20 transfer fails
        if(!success) {
            revert DSCEngine__TransferFailed();
        }

        //  Burn the DSC tokens now held by the DSCEngine contract
        i_dsc.burn(amountDscToBurn);
    }


    /**
     *  @notice Low-level internal function to handle collateral redemption.
     *  @dev Decrements user balance before transferring tokens to prevent reentrancy (CEI 
     *       pattern).
     *  @param from The address whose collateral is being deducted.
     *  @param to The address receiving the redeemed collateral tokens.
     *  @param tokenCollateralAddress The ERC20 token address of the collateral.
     *  @param amountCollateral The amount of collateral tokens to redeem.
     */
    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 amountCollateral) private {
        // Effects: Update state variables before making external calls
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;

        // Log the redemption event for off-chain tracking
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);

        // Interactions: Perform external ERC20 token transfer
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        
        // Check: Ensure the transfer succeeded, revert if it failed
        if(!success){
            revert DSCEngine__TransferFailed();
        }
    }


    /**
     * @notice Retrieves a user's total minted DSC and total collateral value in USD.
     * @dev Internal helper function used to compute account health and collateralization 
     *      status. It aggregates minted stablecoin debt and total collateral value.
     * @param user The address of the target user whose account information is being fetched.
     * @return totalDscMinted The total amount of DSC stablecoins currently minted by the 
     *         user.
     * @return collateralValueInUsd The total USD value of all deposited collateral.
     */
    function _getAccountInformation(address user) private view returns(uint256 totalDscMinted, uint256 collateralValueInUsd) {
        
        // Retrieve(fetches) the total amount of DSC minted (debt) by the user [This represents how much stablecoin the user owes the protocol].
        totalDscMinted = s_DSCMinted[user];

        // Compute the total USD value of all collateral deposited by the user [This typically aggregates token balances and converts them using price feeds.]
        collateralValueInUsd = getAccountCollateralValue(user);
    } 

    
    /**
     * @notice Calculates the health factor of a user's account.
     * @dev Determines if the collateralized ratio meets the safety threshold.
     * @param user The address of the user whose health factor is being evaluated.
     * @return uint256 The calculated health factor (scaled by PRECISION).
    */
    function _healthFactor(address user) private view returns(uint256) {
        
        // Fetch the user's total debt (DSC minted) and the current USD value of their collateral (Retrieve internal accounting data for the specific user)
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);

        // Normalize values and compute final safety ratio
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }


    /**
     * @notice Calculates the equivalent USD value for a given token amount.
     * @dev Fetches the latest price from a Chainlink Aggregator, ensures data staleness is 
     *      checked, and normalizes decimals before calculating the final USD value.
     * @param token The address of the token to be priced.
     * @param amount The amount of the token (in its smallest unit, e.g., Wei).
     * @return The USD value of the token amount (scaled by `PRECISION`).
    */
    function _getUsdValue(address token, uint256 amount) private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        
        // latestRoundData is called via a custom stale-checking wrapper 
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();

        // casting to uint256 is safe because supported Chainlink price feeds are expected to return positive prices
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 priceUint256 = uint256(price);

        // Chainlink price feed results typically have 8 or 18 decimals. 
        // We multiply by ADDITIONAL_FEED_PRECISION to scale up, multiply by token amount, 
        // and divide by PRECISION to get the exact USD value.
        return ((priceUint256 * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }


    /**
     * @notice Calculates the health factor of a user's position.
     * @dev Reverts if the health factor falls below $1$, indicating the position is    
     *      undercollateralized.
     *      If no DSC is minted, it returns the maximum possible uint256 value to prevent 
     *      division by zero.
     * @param totalDscMinted The total amount of DSC (Decentralized Stablecoin) minted by 
     *        the user.
     * @param collateralValueInUsd The total value of the user's collateral in USD.
     * @return healthFactor The calculated health factor (scaled by PRECISION).
    */
    function _calculateHealthFactor(uint256 totalDscMinted,uint256 collateralValueInUsd)
        internal pure returns (uint256)
    {
        // Return max value if no debt is present to prevent a division-by-zero error
        if (totalDscMinted == 0) {
            return type(uint256).max;
        }

        // Apply the liquidation threshold to the collateral value
        // collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        // Calculate the health factor: (collateralAdjustedForThreshold * PRECISION) / totalDscMinted
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }


  
    /**
     * @notice Checks if a user's health factor is above the minimum required threshold.
     * @dev This is an internal function that fetches the user's current health factor, 
     *      compares it to the `MIN_HEALTH_FACTOR` constant, and reverts the transaction 
     *      if the health factor has fallen below the safety limit.
     * @param user The address of the user whose health factor is being evaluated.
     * @custom:reverts DSCEngine__BreaksHealthFactor if the user's health factor is broken.
    */
    function _revertIfHealthFactorIsBroken(address user) internal view {

        // Calculate the user's current health factor based on collateral and minted DSC
        uint256  userHealthFactor = _healthFactor(user);

        // Check if the user's health factor has fallen below the minimum required limit
        if(userHealthFactor < MIN_HEALTH_FACTOR) {

        // Revert the transaction and pass the broken health factor value to the custom error
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }



    /*////////////////////////////  //////////////////////////////////
                              PUBLIC & EXTERNAL View FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates the health factor of a user based on collateral and debt.
     * @dev This is a wrapper function that calls an internal math library/implementation.
     *      A health factor below 1e18 means the user's position is undercollateralized and 
     *      subject to liquidation.
     * @param totalDscMinted The total amount of DSC tokens minted by the user (scaled to 
     *        1e18).
     * @param collateralValueInUsd The total value of the user's collateral in USD (scaled 
     *        to 1e18).
     * @return The calculated health factor of the user (scaled to 1e18).
    */
    function calculateHealthFactor(
        uint256 totalDscMinted,
        uint256 collateralValueInUsd
    )
        external
        pure
        returns (uint256)
    {
        // If no DSC is minted, the health factor is virtually infinite (represented as max uint256). Otherwise, calculate: (Collateral Value * Liquidation Threshold) / Total Minted
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }


    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns(uint256) {
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        // Fetch the latest round data from the Chainlink Aggregator
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();

        // casting to uint256 is safe because supported Chainlink price feeds are expected   to return positive prices
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 priceUint256 = uint256(price);

        // Calculate the token amount: (USD Amount * Precision) / (Token Price * Feed Precision)
        // Example Math ($10 USD requested, Token is $2): ($10 * 1e18) / ($2 * 1e10) = 10e18 / 2e10 = 5e18 (5 tokens)
        return ((usdAmountInWei * PRECISION) / (priceUint256 * ADDITIONAL_FEED_PRECISION));
    }

     
    /**
     * @notice Calculates the total value of all collateral deposited by a specific user.
     * @dev Iterates through the list of supported collateral tokens, fetches the user's 
     * deposited balance for each, converts each balance to its USD value, and returns the sum.
     * @param user The address of the account whose collateral value is being calculated.
     * @return totalCollateralValueInUsd The accumulated value of the user's collateral, denominated in USD.
    */
    function getAccountCollateralValue(address user) public view returns(uint256 totalCollateralValueInUsd){
        // Loop through the entire array of allowed collateral token addresses
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
           
            // Get the current token address from the state variable array
            address token = s_collateralTokens[i];

            // Read the user's deposited balance for this specific token from the nested mapping
            uint256 amount = s_collateralDeposited[user][token];

            // Convert the token balance to USD via an external price feed/oracle function and add it to the tally
            totalCollateralValueInUsd +=  getUsdValue(token, amount);
        }
        // Return the final aggregated USD value
        return totalCollateralValueInUsd;
    }


    /**
     * @notice Calculates the USD value of a specific amount of an asset.
     * @dev Fetches the latest asset price from a Chainlink price feed and applies precision adjustments.
     * @param token The smart contract address of the token being valued.
     * @param amount The quantity of the token to value, scaled to the token's internal decimals.
     * @return The total USD value of the specified token amount, scaled to standard system precision.
    */
    function getUsdValue(address token, uint256 amount) public view returns(uint256) {
        
        // Retrieve and calculate the USD price from the underlying oracle
        return _getUsdValue(token, amount); 
    }


    /**
     * @notice Retrieves the account's total minted DSC and collateral value in USD
     * @dev Calls the internal helper `_getAccountInformation` to fetch the data
     * @param user The address of the user's account to query
     * @return totalDscMinted The total amount of Decentralized Stablecoin (DSC) minted by the user
     * @return collateralValueInUsd The total value of the user's collateral in USD
    */
    function getAccountInformation(address user) external view returns (uint256 totalDscMinted, uint256 collateralValueInUsd) {

        // Fetch and return account data from the internal helper function
        return _getAccountInformation(user);
    }


    /**
     * @notice Retrieves the price feed contract address for a specific token.
     * @dev Looks up the `s_priceFeeds` mapping. If no price feed is registered for the 
     *      token, this will return the zero address (address(0)).
     * @param token The address of the ERC20 or underlying token to look up.
     * @return The address of the Chainlink (or Oracle) price feed contract.
    */
    function getPriceFeed(address token) external view returns(address) {
        // Return the token's associated price feed mapping
        return s_priceFeeds[token];
    }


    /**
     * @notice Returns the list of all currently approved collateral token addresses.
     * @dev Returns the full array of `s_collateralTokens`.
     * @return tokens An array of addresses representing the collateral tokens.
     */
    function getCollateralTokens() external view returns(address[] memory) {
        // Return the state variable holding the accepted collateral tokens
        return s_collateralTokens;
    }


    /**
     * @notice Returns the absolute minimum collateral-to-debt ratio a user must maintain.
     * @dev Pure function that returns the immutable MIN_HEALTH_FACTOR constant.
     * @return The minimum health factor threshold (scaled by 1e18)
     */
    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }


    /**
     * @notice Returns the liquidation threshold for the collateral.
     * @dev This value represents the percentage of collateral at which a position 
     *      becomes undercollateralized and can be liquidated (e.g., $8500 = 85\%$ for 
     *      $1e18$ precision).
     * @return The liquidation threshold as a unsigned 256-bit integer.
    */
    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }


    /**
     *  @notice Returns the liquidation bonus percentage.
     *  @dev This is typically a scaled value (e.g., 10000 = 100%) applied during 
     *  liquidation. 
     *  @return The liquidation bonus as an unsigned integer.
    */
    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }


    /**
     *  @notice Returns the mathematical precision used for liquidation calculations.
     *  @return The precision constant for liquidations.
     */
    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }


    /**
     * @notice Retrieves the amount of a specific collateral token deposited by a user
     * @param user The address of the user whose collateral balance is being queried
     * @param token The address of the collateral token contract
     * @return The amount of deposited collateral token
    */
    function getCollateralBalanceOfUser(address user, address token) external view returns (uint256) {
        return s_collateralDeposited[user][token];
    }


    /**
     * @notice Returns the address of the Decentralized Stablecoin (DSC) contract.
     * @dev Retrieves the `address` typecast of the immutable `i_dsc` state variable.
     * @return dsc The address of the DSC contract.
    */
    function getDscAddress() external view returns(address) {
        return address(i_dsc);
    }


    /**
     *  @notice Returns the precision factor used for calculations.
     *  @dev Retrieves the `PRECISION` constant.
     *  @return The precision value as a uint256.
     */
    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }


    /**
     * @notice Retrieves the current health factor of a specific user.
     * @dev Calls the internal _healthFactor function to calculate the ratio of collateral 
     *      to debt.
     * @param user The address of the user whose health factor is being queried.
     * @return uint256 The user's health factor (usually scaled by 10^18 for precision).
     */
    function getHealthFactor(address user) external view returns (uint256) {
        // Fetch and return the calculated health ratio from the internal logic
        return _healthFactor(user);
    }


    /**
     *  @notice Returns the additional precision applied to the price feed.
     *  @dev This value is often used to scale Oracle feed values (e.g., Chainlink) to 
     *       maintain standard decimals.
     *  @return uint256 The additional feed precision constant.
     */
    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }


    /**
     * @notice Retrieves the address of the Chainlink or custom price feed for a specific collateral token.
     * @dev Looks up the `s_priceFeeds` mapping to return the price feed contract address.
     * @param token The address of the collateral token to query.
     * @return priceFeed The address of the price feed contract associated with the token.
    */
    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        // Return the hardcoded precision scalar constant
        return s_priceFeeds[token];
    }


    

}