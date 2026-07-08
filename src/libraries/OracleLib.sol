// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


/**
 * @title  OracleLib
 * @author LegendaryCode
 * @notice This library is used to check the Chainlink Oracle for stale data.
 *         If a price is stale, function will revert, and render DSCEngine unusable - this 
 *         is by design. 
 *         We want the DSCEngine to freeze if prices become stale.
 * @dev If a price is stale, the function will revert and render the smart contract unusable. 
 *      This is by design to protect the system from utilizing outdated pricing information.
 * 
*/
library OracleLib {
    /// @notice Error thrown when the price feed data is older than the allowed TIMEOUT threshold.
    error OracleLib__StalePrice();

    /// @dev The maximum acceptable duration (3 hours) since the last oracle update before data is considered stale.
    uint256 private constant TIMEOUT = 3 hours;


    /**
     * @notice Checks the latest round data from a Chainlink price feed and validates its freshness.
     * @dev Reverts with `OracleLib__StalePrice` if the difference between the current block time 
     * and the oracle's last update time exceeds the `TIMEOUT` threshold.
     * @param priceFeed The Chainlink AggregatorV3Interface contract instance to query.
     * @return roundId The unique identifier for the pricing round.
     * @return answer The current price asset value reported by the oracle.
     * @return startedAt The timestamp indicating when the pricing round began.
     * @return updatedAt The timestamp indicating when the pricing round was last updated.
     * @return answeredInRound The round ID in which the answer was computed and resolved.
     */
    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed) 
        public 
        view 
        returns(uint88, int256, uint256, uint256, uint88 ) 
    {
    
        // Query the decentralized oracle network for the latest pricing metrics
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // Calculate the total elapsed time since the oracle last updated this data feed
        uint256 secondsSince = block.timestamp - updatedAt;

        // Revert execution if the elapsed time breaks our maximum acceptable delay boundary
        if(secondsSince > TIMEOUT) revert OracleLib__StalePrice();
        
        // Return verified, up-to-date data parameters back to the calling contract
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    } 


}












