// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { PriceFeedChecker } from "./PriceFeedChecker.sol";
import { PERCENTAGE_FACTOR } from "../libraries/PercentageMath.sol";
import { PriceFeedType, IPriceFeedType } from "../interfaces/IPriceFeedType.sol";

// EXCEPTIONS
import { NotImplementedException } from "../interfaces/IErrors.sol";

/// @title Price feed that composes an base asset-denominated price feed with a USD one
/// @notice Used for better price tracking for correlated assets (such as stETH or WBTC) or on networks where
///         only feeds for the native tokens exist
contract CompositePriceFeed is
    PriceFeedChecker,
    AggregatorV3Interface,
    IPriceFeedType
{
    /// @dev Chainlink base asset price feed for the target asset
    AggregatorV3Interface public immutable targetToBasePriceFeed;

    /// @dev Chainlink Base asset / USD price feed
    AggregatorV3Interface public immutable baseToUsdPriceFeed;

    /// @dev Decimals of the returned result.
    uint8 public immutable override decimals;

    /// @dev 10 ^ Decimals of Target / Base price feed, to divide the product of answers
    int256 public immutable answerDenominator;

    /// @dev Price feed description
    string public override description;

    uint256 public constant override version = 1;

    PriceFeedType public constant override priceFeedType =
        PriceFeedType.COMPOSITE_ORACLE;

    bool public constant override skipPriceCheck = true;

    /// @dev Constructor
    /// @param _targetToBasePriceFeed Base asset price feed for target asset
    /// @param _baseToUsdPriceFeed USD price feed for base asset
    constructor(address _targetToBasePriceFeed, address _baseToUsdPriceFeed) {
        targetToBasePriceFeed = AggregatorV3Interface(_targetToBasePriceFeed);
        baseToUsdPriceFeed = AggregatorV3Interface(_baseToUsdPriceFeed);
        description = string(
            abi.encodePacked(
                targetToBasePriceFeed.description(),
                " to USD Composite"
            )
        );
        decimals = baseToUsdPriceFeed.decimals();
        answerDenominator = int256(10**targetToBasePriceFeed.decimals());
    }

    /// @dev Implemented for compatibility, but reverts since Gearbox's price feeds
    ///      do not store historical data.
    function getRoundData(uint80)
        external
        pure
        virtual
        override
        returns (
            uint80, // roundId,
            int256, // answer,
            uint256, // startedAt,
            uint256, // updatedAt,
            uint80 // answeredInRound
        )
    {
        revert NotImplementedException();
    }

    /// @dev Returns the composite USD-denominated price of the asset, computed as (Target / base rate * base / USD rate)
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (
            uint80 roundId0,
            int256 answer0,
            uint256 startedAt0,
            uint256 updatedAt0,
            uint80 answeredInRound0
        ) = targetToBasePriceFeed.latestRoundData();

        _checkAnswer(roundId0, answer0, updatedAt0, answeredInRound0);

        (
            roundId,
            answer,
            startedAt,
            updatedAt,
            answeredInRound
        ) = baseToUsdPriceFeed.latestRoundData();

        _checkAnswer(roundId, answer, updatedAt, answeredInRound);

        answer = (answer0 * answer) / answerDenominator;
    }
}