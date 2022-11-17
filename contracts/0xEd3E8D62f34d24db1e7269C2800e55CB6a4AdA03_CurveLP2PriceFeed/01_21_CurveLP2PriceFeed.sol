// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { AbstractCurveLPPriceFeed } from "./AbstractCurveLPPriceFeed.sol";

import { PriceFeedType } from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeedType.sol";

// EXCEPTIONS
import { ZeroAddressException, NotImplementedException } from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

/// @title CurveLP price feed for 2 assets
contract CurveLP2PriceFeed is AbstractCurveLPPriceFeed {
    /// @dev Price feed of coin 0 in the pool
    AggregatorV3Interface public immutable priceFeed1;

    /// @dev Price feed of coin 1 in the pool
    AggregatorV3Interface public immutable priceFeed2;

    PriceFeedType public constant override priceFeedType =
        PriceFeedType.CURVE_2LP_ORACLE;

    constructor(
        address addressProvider,
        address _curvePool,
        address _priceFeed1,
        address _priceFeed2,
        string memory _description
    ) AbstractCurveLPPriceFeed(addressProvider, _curvePool, _description) {
        if (_priceFeed1 == address(0) || _priceFeed2 == address(0))
            revert ZeroAddressException();

        priceFeed1 = AggregatorV3Interface(_priceFeed1); // F:[OCLP-1]
        priceFeed2 = AggregatorV3Interface(_priceFeed2); // F:[OCLP-1]
    }

    /// @dev Returns the USD price of the pool's LP token
    /// @notice Computes the LP token price as (min_t(price(coin_t)) * virtual_price())
    ///         See more at https://dev.gearbox.fi/docs/documentation/oracle/curve-pricefeed
    function latestRoundData()
        external
        view
        virtual
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = priceFeed1
            .latestRoundData(); // F:[OCLP-4]

        // Sanity check for the Chainlink pricefeed
        _checkAnswer(roundId, answer, updatedAt, answeredInRound);

        (
            uint80 roundId2,
            int256 answer2,
            uint256 startedAt2,
            uint256 updatedAt2,
            uint80 answeredInRound2
        ) = priceFeed2.latestRoundData(); // F:[OCLP-4]

        // Sanity check for the Chainlink pricefeed
        _checkAnswer(roundId2, answer2, updatedAt2, answeredInRound2);

        if (answer2 < answer) {
            roundId = roundId2;
            answer = answer2;
            startedAt = startedAt2;
            updatedAt = updatedAt2;
            answeredInRound = answeredInRound2;
        } // F:[OCLP-4]

        uint256 virtualPrice = curvePool.get_virtual_price();

        // Checks that virtual_price is in within bounds
        virtualPrice = _checkAndUpperBoundValue(virtualPrice); // F: [OCLP-7]

        answer = (answer * int256(virtualPrice)) / decimalsDivider; // F:[OCLP-4]
    }
}