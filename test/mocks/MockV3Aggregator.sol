// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MockV3Aggregator
 * @notice Based on the FluxAggregator contract
 * @notice Use this contract when you need to test
 *         other contract's ability to read data from an
 *         aggregator contract.
 */
contract MockV3Aggregator {

    /// @notice The version of the Aggregator interface
    uint256 public constant version = 0;

    /// @notice State variables representing standard Chainlink V3 Aggregator properties
    uint8 public decimals;
    int256 public latestAnswer;
    uint256 public latestTimestamp;
    uint256 public latestRound;

    /// @notice Historical mappings to keep track of past round data
    mapping(uint256 => int256) public getAnswer;
    mapping(uint256 => uint256) public getTimestamp;
    mapping(uint256 => uint256) private getStartedAt;


    /**
     * @notice Initializes the aggregator with decimals and an initial answer
     * @param _decimals The number of decimals the answer has
     * @param _initialAnswer The starting value for the price feed
    */
    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        updateAnswer(_initialAnswer);
    }


    /**
     * @notice Updates the latest round data with a new answer
     * @dev Increments the round ID and sets the timestamp to the current block time
     * @param _answer The new price/value to set
    */
    function updateAnswer(int256 _answer) public {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = block.timestamp;
        getStartedAt[latestRound] = block.timestamp;
    }


    /**
     * @notice Manually forces an update for a specific round
     * @param _roundId The ID of the round to update
     * @param _answer The answer for this specific round
     * @param _timestamp The timestamp when the answer was last updated
     * @param _startedAt The timestamp when this round started
    */
    function updateRoundData(uint80 _roundId, int256 _answer, uint256 _timestamp, uint256 _startedAt) public {
        latestRound = _roundId;
        latestAnswer = _answer;
        latestTimestamp = _timestamp;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = _timestamp;
        getStartedAt[latestRound] = _startedAt;
    }


    /**
     * @notice Retrieves historical data for a specific round
     * @param _roundId The ID of the round to retrieve data for
     * @return roundId The round ID
     * @return answer The price/value for the given round
     * @return startedAt The timestamp when the round started
     * @return updatedAt The timestamp when the round was last updated
     * @return answeredInRound The round ID in which the answer was computed (same as       
     *         roundId here)
    */
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, getAnswer[_roundId], getStartedAt[_roundId], getTimestamp[_roundId], _roundId);
    }


    /**
     * @notice Retrieves data for the most recent round
     * @return roundId The most recent round ID
     * @return answer The latest price/value
     * @return startedAt The timestamp when the latest round started
     * @return updatedAt The timestamp when the latest round was updated
     * @return answeredInRound The round ID in which the answer was computed
    */
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            uint80(latestRound),
            getAnswer[latestRound],
            getStartedAt[latestRound],
            getTimestamp[latestRound],
            uint80(latestRound)
        );
    }

    function description() external pure returns (string memory) {
        return "v0.6/tests/MockV3Aggregator.sol";
    }
}