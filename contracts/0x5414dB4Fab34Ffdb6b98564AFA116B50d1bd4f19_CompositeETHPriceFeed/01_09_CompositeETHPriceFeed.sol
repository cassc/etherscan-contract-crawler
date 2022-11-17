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

/// @title Price feed that composes an ETH price feed with a USD one
/// @notice Used to avoid price feed discrepancies for ETH-correlated assets, such as stETH
contract CompositeETHPriceFeed is
    PriceFeedChecker,
    AggregatorV3Interface,
    IPriceFeedType
{
    /// @dev Chainlink ETH price feed for the target asset
    AggregatorV3Interface public immutable targetEthPriceFeed;

    /// @dev Chainlink ETH/USD price feed
    AggregatorV3Interface public immutable ethUsdPriceFeed;

    /// @dev Decimals of the returned result.
    uint8 public immutable override decimals;

    /// @dev 10 ^ Decimals of Target / ETH price feed, to divide the product of answers
    int256 public immutable answerDenominator;

    /// @dev Price feed description
    string public override description;

    uint256 public constant override version = 1;

    PriceFeedType public constant override priceFeedType =
        PriceFeedType.COMPOSITE_ETH_ORACLE;

    bool public constant override skipPriceCheck = true;

    /// @dev Constructor
    /// @param _targetEthPriceFeed ETH price feed for target asset
    /// @param _ethUsdPriceFeed USD price feed for ETH
    constructor(address _targetEthPriceFeed, address _ethUsdPriceFeed) {
        targetEthPriceFeed = AggregatorV3Interface(_targetEthPriceFeed);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        description = string(
            abi.encodePacked(
                targetEthPriceFeed.description(),
                " ETH/USD Composite"
            )
        );
        decimals = ethUsdPriceFeed.decimals();
        answerDenominator = int256(10**targetEthPriceFeed.decimals());
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
        revert NotImplementedException(); // F:[LPF-2]
    }

    /// @dev Returns the composite USD-denominated price of the asset, computed as (Target / ETH rate * ETH / USD rate)
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
        ) = targetEthPriceFeed.latestRoundData();

        _checkAnswer(roundId0, answer0, updatedAt0, answeredInRound0);

        (
            roundId,
            answer,
            startedAt,
            updatedAt,
            answeredInRound
        ) = ethUsdPriceFeed.latestRoundData();

        _checkAnswer(roundId, answer, updatedAt, answeredInRound);

        answer = (answer0 * answer) / answerDenominator;
    }
}