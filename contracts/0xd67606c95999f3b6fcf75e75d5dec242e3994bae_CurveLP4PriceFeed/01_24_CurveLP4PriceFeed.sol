// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {AbstractCurveLPPriceFeed} from "./AbstractCurveLPPriceFeed.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {PriceFeedType} from "../LPPriceFeed.sol";

// EXCEPTIONS
import {
    ZeroAddressException, NotImplementedException
} from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

/// @title CurveLP pricefeed for 4 assets
contract CurveLP4PriceFeed is AbstractCurveLPPriceFeed {
    /// @dev Price feed of coin 0 in the pool
    AggregatorV3Interface public immutable priceFeed1;

    /// @dev Price feed of coin 1 in the pool
    AggregatorV3Interface public immutable priceFeed2;

    /// @dev Price feed of coin 2 in the pool
    AggregatorV3Interface public immutable priceFeed3;

    /// @dev Price feed of coin 3 in the pool
    AggregatorV3Interface public immutable priceFeed4;

    PriceFeedType public constant override priceFeedType = PriceFeedType.CURVE_4LP_ORACLE;

    constructor(
        address addressProvider,
        address _curvePool,
        address _priceFeed1,
        address _priceFeed2,
        address _priceFeed3,
        address _priceFeed4,
        string memory _description
    ) AbstractCurveLPPriceFeed(addressProvider, _curvePool, _description) {
        if (
            _priceFeed1 == address(0) || _priceFeed2 == address(0) || _priceFeed3 == address(0)
                || _priceFeed4 == address(0)
        ) revert ZeroAddressException();

        priceFeed1 = AggregatorV3Interface(_priceFeed1); // F:[OCLP-1]
        priceFeed2 = AggregatorV3Interface(_priceFeed2); // F:[OCLP-1]
        priceFeed3 = AggregatorV3Interface(_priceFeed3); // F:[OCLP-1]
        priceFeed4 = AggregatorV3Interface(_priceFeed4); // F:[OCLP-1]
    }

    /// @dev Returns the USD price of the pool's LP token
    /// @notice Computes the LP token price as (min_t(price(coin_t)) * virtual_price())
    ///         See more at https://dev.gearbox.fi/docs/documentation/oracle/curve-pricefeed
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint80 roundIdA;
        int256 answerA;
        uint256 startedAtA;
        uint256 updatedAtA;
        uint80 answeredInRoundA;

        (roundId, answer, startedAt, updatedAt, answeredInRound) = priceFeed1.latestRoundData(); // F:[OCLP-6]

        // Sanity check for chainlink pricefeed
        _checkAnswer(roundId, answer, updatedAt, answeredInRound);

        (roundIdA, answerA, startedAtA, updatedAtA, answeredInRoundA) = priceFeed2.latestRoundData(); // F:[OCLP-6]

        // Sanity check for chainlink pricefeed
        _checkAnswer(roundIdA, answerA, updatedAtA, answeredInRoundA);

        if (answerA < answer) {
            roundId = roundIdA;
            answer = answerA;
            startedAt = startedAtA;
            updatedAt = updatedAtA;
            answeredInRound = answeredInRoundA;
        } // F:[OCLP-6]

        (roundIdA, answerA, startedAtA, updatedAtA, answeredInRoundA) = priceFeed3.latestRoundData(); // F:[OCLP-6]

        // Sanity check for chainlink pricefeed
        _checkAnswer(roundIdA, answerA, updatedAtA, answeredInRoundA);

        if (answerA < answer) {
            roundId = roundIdA;
            answer = answerA;
            startedAt = startedAtA;
            updatedAt = updatedAtA;
            answeredInRound = answeredInRoundA;
        } // F:[OCLP-6]

        (roundIdA, answerA, startedAtA, updatedAtA, answeredInRoundA) = priceFeed4.latestRoundData(); // F:[OCLP-6]

        // Sanity check for chainlink pricefeed
        _checkAnswer(roundIdA, answerA, updatedAtA, answeredInRoundA);

        if (answerA < answer) {
            roundId = roundIdA;
            answer = answerA;
            startedAt = startedAtA;
            updatedAt = updatedAtA;
            answeredInRound = answeredInRoundA;
        } // F:[OCLP-6]

        uint256 virtualPrice = curvePool.get_virtual_price();

        // Checks that virtual_priceis in limits
        virtualPrice = _checkAndUpperBoundValue(virtualPrice); // F: [OCLP-7]

        answer = (answer * int256(virtualPrice)) / decimalsDivider; // F:[OCLP-4]
    }
}