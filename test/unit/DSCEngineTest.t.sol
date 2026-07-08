
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import { ERC20Mock } from "../../test/mocks/ERC20Mock.sol";
import { MockFailedTransfer } from "../../test/mocks/MockFailedTransfer.sol";
import { MockV3Aggregator } from "../../test/mocks/MockV3Aggregator.sol";
import { MockFailedMintDSC } from "../mocks/MockFailedMintDSC.sol";


/**
 * @title DSCEngineTest 
 * @author LegendaryCode
 * @notice Test suite for the DSCEngine core system logic.
 * @dev Inherits from Foundry's Test contract to utilize standard testing primitives.
*/
contract DSCEngineTest is  Test {
    
    /// @notice Core protocol deployment state variables
    DeployDSC  deployer;
    DecentralizedStableCoin dsc;
    DSCEngine  dsce;
    HelperConfig  config;

    /// @notice Infrastructure and Price Feed dependencies
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    /// @notice Test environment configurations
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public   AMOUNT_TO_MINT = 100 ether;

    // Dynamic arrays utilized during temporary constructor configurations
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;


    /**
     * @notice Initializes the testing sandbox environment before each unit test run.
     * @dev Deploys the main ecosystem and mints initial mock collateral tokens to the dummy 
     *      user.
    */
    function setUp() public{
        // Run core system initialization via deployment script
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();

        // Fetch valid mock network parameters from helper configuration
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
        
        // Provide the test user with mock tokens for collateral deposit actions
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }



     /*//////////////////////////////////////////////////////////////
                             Constructor TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies engine deployment reverts when mismatching lengths of tokens and 
     *         price feeds are supplied.
     * @dev Expects a custom error selector 
     *      `DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength` on failure.
     */
    function testRevertIfTokenLengthDoesntMatchPriceFeeds() public {

        /// @notice Configure an unbalanced setup: 1 supported token address vs 2 active price feeds
        tokenAddresses.push(weth);

        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        /// @notice Instruct EVM state to intercept next transaction with matching revert signature
        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);

        // Intentionally trigger deployment crash to fulfill test criteria
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }


    /**
     * @notice Tests that the DSCEngine constructor properly initializes price feeds and 
     *         collateral tokens
     * @dev Verifies that the deployed DSCEngine records the correct price feed addresses 
     *      and collateral list
     */
    function testConstructorSetsPriceFeedsAndCollateralTokens() public {
        // Setup collateral and price feed arrays
        address[] memory tokens = new address[](2);
        address[] memory feeds = new address[](2);

        tokens[0] = weth;
        tokens[1] = USER;

        feeds[0] = ethUsdPriceFeed;
        feeds[1] = btcUsdPriceFeed;

        // Initialize the DSCEngine contract
        DSCEngine engine = new DSCEngine(tokens, feeds, address(dsc));

        // Assert that price feeds are mapped correctly
        assertEq(engine.getPriceFeed(weth), ethUsdPriceFeed);
        assertEq(engine.getPriceFeed(USER), btcUsdPriceFeed);

        // Retrieve and assert collateral token array matches input
        address[] memory collateralTokens =  engine.getCollateralTokens();

        assertEq(collateralTokens[0], weth);

        assertEq(collateralTokens[1], USER);

        // Assert DSC token address is correctly set
        assertEq(engine.getDscAddress(), address(dsc));
    }


    /**
     * @notice Verifies that a newly deployed DSCEngine initializes user account
     *         state with zero DSC minted.
     * @dev Deploys a fresh DSCEngine instance with valid token and price feed
     *      mappings, then checks that an account with no interactions has no 
     *       outstanding DSC debt.
    */
     function testConstructorInitializesCorrectly() public {
        // Create arrays for supported collateral tokens and their corresponding price feeds.
        address[] memory tokens = new address[](2);
        address[] memory feeds = new address[](2);

        // Configure supported collateral assets.
        tokens[0] = weth;
        tokens[1] = makeAddr("wbtc");

        // Associate each collateral token with its USD price feed.
        feeds[0] = ethUsdPriceFeed;
        feeds[1] = btcUsdPriceFeed;

        // Deploy a new DSCEngine using the configured collateral and price feeds.
        DSCEngine engine = new  DSCEngine(tokens, feeds, address(dsc));

        // Retrieve the user's account information immediately after deployment.
        (uint256 totalDscMinted, ) = engine.getAccountInformation(USER);

        // A user who has not interacted with the protocol should have zero DSC minted.
        assertEq(totalDscMinted, 0);
     }



    /*//////////////////////////////////////////////////////////////
                             Price TESTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Verifies that getUsdValue correctly converts a collateral amount
     *         into its USD equivalent using the configured price feed.
     * @dev Assumes the mock ETH/USD price feed returns 2,000 USD per ETH.
     *      Therefore, 15 ETH should be valued at 30,000 USD.
     */
    function testGetUsdValue() public {
        // Amount of ETH to convert to its USD value.
        uint256 ethAmount = 15e18;

        // Expected USD value: 15 ETH × $2,000 = $30,000.
        uint256 expectedUsd = 30000e18;

        // Calculate the USD value using the DSCEngine.
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);

        // The calculated USD value should match the expected result.
        assertEq(expectedUsd, actualUsd);
    }


    /**
     * @notice Verifies that the DSCEngine correctly converts a USD amount to the equivalent 
     *          WETH amount.
     * @dev Tests the `getTokenAmountFromUsd` function with an expected 2000 USD/WETH oracle 
     *      price.
     *      Asserts that 100 USD correctly yields 0.05 WETH.
    */
    function testGetTokenAmountFromUsd() public {
        // Arrange: USD amount to convert into its equivalent WETH value.
        uint256 usdAmount = 100 ether;
        uint256  expectedWeth = 0.05 ether;

        // Act: Call the target function within the DSCEngine
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);

        // Assert: Verify that the actual WETH returned matches the expected calculated amount
        assertEq(expectedWeth, actualWeth);
    }



    /*//////////////////////////////////////////////////////////////
                             depositCollateral TESTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Tests that depositing zero collateral correctly reverts.
     * @dev Verifies the `DSCEngine__NeedsMoreThanZero` custom error is triggered.
     */
    function testRevertIfCollateralZero() public {
        // Arrange: Set up the user context and approve maximum test collateral
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        // Act & Assert: Expect a revert when passing 0 as the collateral amount
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }


    /**
     * @notice Verifies that depositing an unsupported collateral token reverts.
     * @dev Creates a mock ERC20 token that is not registered as an approved
     *      collateral asset and expects the transaction to revert with
     *      DSCEngine__NotAllowedToken.
     */
    function testRevertsWithUnapprovedCollateral() public {
        // Deploy a mock token that is not part of the DSCEngine's approved collateral list.
        ERC20Mock ranToken =  new ERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL);

        // Simulate the deposit from the user's account.
        vm.startPrank(USER);

        // The deposit should fail because the token is not an approved collateral asset.
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);

        vm.stopPrank();
    }


    /**
     * @notice Sets up a test state where USER has deposited WETH as collateral.
     * @dev Grants the DSCEngine permission to transfer the user's WETH, deposits
     *      the configured collateral amount, then executes the modified test.
     */
    modifier depositedCollateral()  {
        // Execute all setup actions as the test user.
        vm.startPrank(USER);

        // Authorize the DSCEngine to transfer the user's collateral.
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        // Deposit WETH so subsequent tests start with collateral already supplied.
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);

        vm.stopPrank();

        _;
    }


    /**
     * @notice Verifies that depositing collateral does not automatically mint DSC.
     * @dev Uses the `depositedCollateral` modifier to pre-fund the user's account 
     *      with collateral, then confirms the user's DSC balance remains zero. 
    */    
    function testCanDepositCollateralWithoutMinting() public depositedCollateral {
        // Retrieve the user's DSC balance after depositing collateral.
        uint256 userBalance = dsc.balanceOf(USER);
        
        // Depositing collateral alone should not mint any DSC.
        assertEq(userBalance, 0);
    }


    /**
     * @notice Verifies that account information is updated correctly after
     *         depositing collateral.
     * @dev Uses the `depositedCollateral` modifier to initialize the user's
     *      position, then checks that no DSC has been minted and that the
     *      recorded collateral value corresponds to the deposited amount.
     */
    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        // Retrieve the user's debt and collateral value from the DSCEngine.
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);

        uint256 expectedTotalDscMinted = 0;

        // Convert the reported USD collateral value back into WETH for comparison.
        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);

        // Depositing collateral alone should not mint DSC.
        assertEq(totalDscMinted, expectedTotalDscMinted);

        // The recorded collateral should equal the amount originally deposited.
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount,  "Deposited collateral mismatch");
    }


    /**
     * @notice Tests that the DSCEngine reverts when a collateral transfer fails.
     * @dev Creates a mock token that simulates a failed transfer, approves the engine, 
     *       and verifies that the depositCollateral function catches the failure.
     */
    function testRevertsIfTransferFromFails() public {
        // Setup a mock token where the `transferFrom` function returns false
        MockFailedTransfer failedToken = new MockFailedTransfer(USER);

        address[] memory tokens = new address[](1);
        address[] memory feeds = new address[](1);

        tokens[0] = address(failedToken);
        feeds[0] = ethUsdPriceFeed;

        // Initialize the engine with our mock token and feed
        DSCEngine engine =
            new DSCEngine(tokens, feeds, address(dsc));

        // Simulate the deposit from the user's account)
        vm.startPrank(USER);

        // Allow the DSCEngine to attempt transferring the collateral.
        failedToken.approve(address(engine), AMOUNT_COLLATERAL);

        // Expect the specific DSCEngine__TransferFailed custom error to be thrown
        vm.expectRevert(DSCEngine.DSCEngine__TransferFailed.selector);

        // The deposit should revert because transferFrom fails.
        engine.depositCollateral(
            address(failedToken),
            AMOUNT_COLLATERAL
        );

        vm.stopPrank();
    }



    /*//////////////////////////////////////////////////////////////
                             mintDsc TESTS
    //////////////////////////////////////////////////////////////*/
    /**
     *  @notice Tests that the DSCEngine reverts when attempting to mint 0 DSC.
     *  @dev Expects the mint operation to revert with DSCEngine__NeedsMoreThanZero
     *       when the amount specified is zero.
     */
    function testRevertIfMintAmountIsZero() public {
        vm.startPrank(USER);
 
        // Approve collateral transfer   
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        // Minting zero DSC should always revert due to invalid input.
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.mintDsc(0);

        vm.stopPrank();
    }


    /**
     * @notice Verifies that a user can successfully mint DSC against deposited collateral.
     * @dev Uses the `depositedCollateral` modifier to ensure the user has sufficient
     *      collateral before minting DSC.
     */
    function testCanMintDsc() public  depositedCollateral {
         vm.startPrank(USER);

        // Mint DSC backed by the user's collateral position.
        dsce.mintDsc(100 ether);

        // Retrieve the user's DSC balance after minting.
        uint256 userBalance = dsc.balanceOf(USER);

        // The minted balance should match the expected amount.
        assertEq(userBalance, AMOUNT_TO_MINT);

        vm.stopPrank();
    }


    /**
     * @notice Verifies that minting DSC reverts when it would break the user's health 
     *         factor.
     * @dev Uses a deposited collateral position, then attempts to mint an excessive amount
     *      of DSC that would make the position undercollateralized.
     */
    function testMintRevertsIfHealthFactorBroken() public depositedCollateral {
        vm.startPrank(USER);

        // Minting too much DSC should revert due to insufficient collateral backing.
        // Fails because it would push the health factor below the minimum threshold.
        vm.expectRevert();

        dsce.mintDsc(200000000 ether);

        vm.stopPrank();
    }


    /**
     * @notice Confirms the engine reverts if the DSC token minting process fails
     * @dev Uses a mock DSC token that intentionally fails minting to simulate a
     *      broken ERC20 implementation or external failure. The DSCEngine must
     *      revert with DSCEngine__MintFailed when minting fails after collateral deposit.
     */
    function testRevertsIfMintFails() public {
        // Arrange -  Deploy engine contract with the broken mock DSC token
        MockFailedMintDSC mockDsc = new MockFailedMintDSC(address(this));

        // Configure DSCEngine with WETH as the only collateral asset.
        tokenAddresses = [weth];
        priceFeedAddresses = [ethUsdPriceFeed];

        // Set up engine owner context for deployment.
        address owner = msg.sender;

        vm.prank(owner);
        // Deploy engine contract with the broken mock DSC token
        DSCEngine mockDsce = new DSCEngine(tokenAddresses, priceFeedAddresses, address(mockDsc));

        // Transfer ownership of the mock DSC to the engine so it can attempt minting.
        mockDsc.transferOwnership(address(mockDsce));

        // Arrange - Simulate user interaction
        vm.startPrank(USER);

        // Allow engine to transfer user's collateral.
        ERC20Mock(weth).approve(address(mockDsce), AMOUNT_COLLATERAL);

        // Expect revert because DSC minting will fail after collateral deposit.
        vm.expectRevert(DSCEngine.DSCEngine__MintFailed.selector);

        // Trigger execution which should fail during the mint phase
        mockDsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT);

        vm.stopPrank();
    }



    /*//////////////////////////////////////////////////////////////
                             burnDsc TESTS
    //////////////////////////////////////////////////////////////*/
    function testCanBurnDsc() public depositedCollateral
    {
        vm.startPrank(USER);

        // Mint DSC against the user's collateral position.
        dsce.mintDsc(100 ether);

        // Approve DSCEngine to burn the user's DSC.
        dsc.approve(address(dsce), 100 ether);

        // Burn the entire minted DSC balance.
        dsce.burnDsc(100 ether);

        // Retrieve updated account information after burning.
        (uint256 minted,) = dsce.getAccountInformation(USER);

        // User should have no remaining minted DSC debt.
        assertEq(minted, 0);

        vm.stopPrank();
    }


    /**
     * @notice Verifies that a user can successfully burn all minted Decentralized Stable 
     *        Coin (DSC).
     * @dev Mints DSC, approves the Engine to spend it, burns it, and asserts that the 
     *      user's DSC balance is 0.
    */
    function testCanBurnDSC() public depositedCollateral {
        vm.startPrank(USER);

        // Mint the required amount of DSC tokens for testing
        dsce.mintDsc(AMOUNT_TO_MINT);

        // Approve the DSCEngine to burn the minted DSC on behalf of the user
        dsc.approve(address(dsce), AMOUNT_TO_MINT);

        // Burn all minted DSC, restoring balance to zero.
        dsce.burnDsc(AMOUNT_TO_MINT);

        vm.stopPrank();

        // Verify that the user's DSC balance is completely cleared (zero)
        assertEq(dsc.balanceOf(USER), 0);
    }


    /**
     *  @notice Confirms that burning zero DSC tokens triggers a revert
     *  @dev Sets up a user position with collateral and minted DSC, then expects
     *       burnDsc(0) to revert with DSCEngine__NeedsMoreThanZero.
     */
    function testRevertsIfBurnAmountIsZero() public {
        vm.startPrank(USER);

        // Approve and deposit collateral while minting DSC in a single step.
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        // Deposit collateral and mint DSC to create a baseline state
        dsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT);

        // Burning zero should always revert due to invalid input.
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.burnDsc(0);
        
        vm.stopPrank();
    }


    /**
     * @notice Verifies that a user cannot burn more DSC than they currently possess.
     * @dev Expects the transaction to revert when attempting to burn more tokens
     *      than the user holds in their DSC balance.
     */
    function testCantBurnMoreThanUserHas() public {
        // Impersonate the USER address for the next transaction
        vm.prank(USER);

        // Burning more DSC than owned should always fail.
        vm.expectRevert();

        // Attempt to burn 1 DSC, which should trigger a revert since the balance is insufficient
        dsce.burnDsc(1);
    }



    /*//////////////////////////////////////////////////////////////
                             redeemCollateral TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies that a user can successfully redeem their deposited collateral.
     * @dev Uses the `depositedCollateral` modifier to ensure the user starts with an
     *      existing collateral position, then redeems the full amount.
     */
    function testCanRedeemCollateral() public depositedCollateral
    {
        vm.startPrank(USER);

        // Redeem all previously deposited WETH collateral.
        dsce.redeemCollateral(
            weth,
            AMOUNT_COLLATERAL
        );

        vm.stopPrank();
    }



    /*//////////////////////////////////////////////////////////////
                             depositCollateralAndMintDsc TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests the ability to deposit collateral and mint DSC in a single atomic 
     *         transaction.
     * @dev Uses the combined `depositCollateralAndMintDsc` function to ensure that
     *      approval, collateral deposit, and DSC minting all succeed atomically.
     */
    function testDepositAndMintTogether() public {
        // Impersonate the USER address to simulate a real user interacting with the contract
        vm.startPrank(USER);

        // Approve DSCEngine to transfer the user's WETH collateral.
        ERC20Mock(weth).approve(
            address(dsce),
            AMOUNT_COLLATERAL
        );

        // Deposit collateral and mint DSC in a single transaction, then verify balances
        dsce.depositCollateralAndMintDsc(
            weth,
            AMOUNT_COLLATERAL,
            100 ether
        );

        vm.stopPrank();
    }


    function testRevertsIfMintedDscBreaksHealthFactor() public {
        
    }



    /*//////////////////////////////////////////////////////////////
                             redeemCollateralForDsc TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests the ability to redeem collateral by simultaneously burning DSC tokens
     * @dev Mints DSC, approves the DSCEngine to spend it, and calls redeemCollateralForDsc 
     *      to swap 1 WETH for 100 DSC.
     */
    function testRedeemCollateralForDsc() public depositedCollateral
    {
        // Act as the user for subsequent calls
        vm.startPrank(USER);

        //  Mint the required amount of DSC to the user's account
        dsce.mintDsc(100 ether);

        //  Approve the DSCEngine to pull/burn the 100 DSC
        dsc.approve(address(dsce), 100 ether);

        // Burn 100 DSC and redeem 1 ETH worth of collateral.
        dsce.redeemCollateralForDsc(
            weth,
            1 ether,
            100 ether
        );

        vm.stopPrank();
    }



     /*//////////////////////////////////////////////////////////////
                             liquidate TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies that a healthy position cannot be liquidated.
     * @dev Expects the liquidation attempt to revert with
     *      is above the liquidation threshold.
     */
    function testCantLiquidateHealthyUser() public
    {
        // Liquidation should fail because the user's position is sufficiently collateralized.
        vm.expectRevert(
            DSCEngine.DSCEngine__HealthFactorOk.selector
        );

        //  Attempt to liquidate a healthy user, which should fail because their health factor is > 1
        dsce.liquidate(weth, USER, 100 ether);
    }



    /*//////////////////////////////////////////////////////////////
                             getAccountCollateralValue TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies that the user's total collateral value is correctly
     *         reported in USD.
     * @dev Uses the `depositedCollateral` modifier to initialize the user's
     *      position. Assumes the mock ETH/USD price feed returns 2,000 USD per ETH,
     *      making 10 ETH worth 20,000 USD.
     */
    function testGetAccountCollateralValue() public depositedCollateral
    {
        // Retrieve the total USD value of the user's deposited collateral.
        uint256 value = dsce.getAccountCollateralValue(USER);

        // 10 ETH × $2,000/ETH = $20,000.
        assertEq(value, 20000e18); 
    }



}











