// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AbstractCurveLPPriceFeed} from "./AbstractCurveLPPriceFeed.sol";

import {PriceFeedType} from "../LPPriceFeed.sol";
import {FixedPoint} from "../../integrations/balancer/FixedPoint.sol";

// EXCEPTIONS
import {ZeroAddressException} from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

uint256 constant DECIMALS = 10 ** 18;
uint256 constant USD_FEED_DECIMALS = 10 ** 8;

/// @title CurveLP price feed for crypto pools
contract CurveCryptoLPPriceFeed is AbstractCurveLPPriceFeed {
    using FixedPoint for uint256;

    /// @dev Price feed of coin 0 in the pool
    AggregatorV3Interface public immutable priceFeed1;

    /// @dev Price feed of coin 1 in the pool
    AggregatorV3Interface public immutable priceFeed2;

    /// @dev Price feed of coin 2 in the pool
    AggregatorV3Interface public immutable priceFeed3;

    /// @dev Number of coins in the pool (2 or 3)
    uint16 public immutable nCoins;

    PriceFeedType public constant override priceFeedType = PriceFeedType.CURVE_CRYPTO_ORACLE;

    constructor(
        address addressProvider,
        address _curvePool,
        address _priceFeed1,
        address _priceFeed2,
        address _priceFeed3,
        string memory _description
    ) AbstractCurveLPPriceFeed(addressProvider, _curvePool, _description) {
        if (_priceFeed1 == address(0) || _priceFeed2 == address(0)) {
            revert ZeroAddressException();
        }

        priceFeed1 = AggregatorV3Interface(_priceFeed1);
        priceFeed2 = AggregatorV3Interface(_priceFeed2);
        priceFeed3 = AggregatorV3Interface(_priceFeed3);

        nCoins = _priceFeed3 == address(0) ? 2 : 3;
    }

    /// @dev Returns the USD price of Curve Tricrypto pool's LP token
    /// @notice Computes the LP token price as n * (prod_i(price(coin_i)))^(1/n) * virtual_price()
    function latestRoundData()
        external
        view
        virtual
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint80 roundIdCurrent;
        int256 answerCurrent;
        uint256 updatedAtCurrent;
        uint80 answeredInRoundCurrent;

        (roundId, answerCurrent, startedAt, updatedAt, answeredInRound) = priceFeed1.latestRoundData();

        // Sanity check for the Chainlink pricefeed
        _checkAnswer(roundId, answerCurrent, updatedAt, answeredInRound);

        uint256 product = uint256(answerCurrent) * DECIMALS / USD_FEED_DECIMALS;

        (roundIdCurrent, answerCurrent,, updatedAtCurrent, answeredInRoundCurrent) = priceFeed2.latestRoundData();

        // Sanity check for the Chainlink pricefeed
        _checkAnswer(roundIdCurrent, answerCurrent, updatedAtCurrent, answeredInRoundCurrent);

        product = product.mulDown(uint256(answerCurrent) * DECIMALS / USD_FEED_DECIMALS);

        if (nCoins == 3) {
            (roundIdCurrent, answerCurrent,, updatedAtCurrent, answeredInRoundCurrent) = priceFeed3.latestRoundData();

            // Sanity check for the Chainlink pricefeed
            _checkAnswer(roundIdCurrent, answerCurrent, updatedAtCurrent, answeredInRoundCurrent);

            product = product.mulDown(uint256(answerCurrent) * DECIMALS / USD_FEED_DECIMALS);
        }

        uint256 virtualPrice = curvePool.virtual_price();

        // Checks that virtual_price is within bounds
        virtualPrice = _checkAndUpperBoundValue(virtualPrice);

        answer = int256(product.powDown(DECIMALS / nCoins).mulDown(nCoins * virtualPrice));

        answer = answer * int256(USD_FEED_DECIMALS) / int256(DECIMALS);
    }
}