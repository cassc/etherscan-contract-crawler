// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {AggregatorV3Interface} from "AggregatorV3Interface.sol";
import {IGRouterOracle} from "IGRouterOracle.sol";
import {ICurve3Pool} from "ICurve3Pool.sol";
import {Errors} from "Errors.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared
contract FixedStablecoins {
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    ICurve3Pool public constant curvePool =
        ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    uint256 constant DAI_DECIMALS = 1_000_000_000_000_000_000;
    uint256 constant USDC_DECIMALS = 1_000_000;
    uint256 constant USDT_DECIMALS = 1_000_000;
    uint256 constant THREE_CRV_DECIMALS = 1_000_000_000_000_000_000;

    constructor() {}

    function getToken(uint256 _index) public pure returns (address) {
        if (_index == 0) {
            return DAI;
        } else if (_index == 1) {
            return USDC;
        } else if (_index == 2) {
            return USDT;
        } else {
            return THREE_CRV;
        }
    }

    function getDecimal(uint256 _index) public pure returns (uint256) {
        if (_index == 0) {
            return DAI_DECIMALS;
        } else if (_index == 1) {
            return USDC_DECIMALS;
        } else if (_index == 2) {
            return USDT_DECIMALS;
        } else {
            return THREE_CRV_DECIMALS;
        }
    }
}

contract RouterOracle is FixedStablecoins, IGRouterOracle {
    uint256 constant CHAINLINK_FACTOR = 1_00_000_000;
    uint256 constant NO_OF_AGGREGATORS = 3;
    uint256 constant STALE_CHECK = 86_400; // 24 Hours

    address public immutable daiUsdFeed;
    address public immutable usdcUsdFeed;
    address public immutable usdtUsdFeed;

    constructor(address[NO_OF_AGGREGATORS] memory aggregators) {
        daiUsdFeed = aggregators[0];
        usdcUsdFeed = aggregators[1];
        usdtUsdFeed = aggregators[2];
    }

    /// @notice Get estimate USD price of a stablecoin amount
    /// @param _amount Token amount
    /// @param _index Index of token
    function stableToUsd(uint256 _amount, uint256 _index)
        external
        view
        override
        returns (uint256, bool)
    {
        if (_index == 3)
            return (
                (curvePool.get_virtual_price() * _amount) / THREE_CRV_DECIMALS,
                true
            );
        (uint256 price, bool isStale) = getPriceFeed(_index);
        return ((_amount * price) / CHAINLINK_FACTOR, isStale);
    }

    /// @notice Get LP token value of input amount of single token
    function usdToStable(uint256 _amount, uint256 _index)
        external
        view
        override
        returns (uint256, bool)
    {
        if (_index == 3)
            return (
                (curvePool.get_virtual_price() * _amount) / THREE_CRV_DECIMALS,
                true
            );
        (uint256 price, bool isStale) = getPriceFeed(_index);
        return ((_amount * CHAINLINK_FACTOR) / price, isStale);
    }

    /// @notice Get price from aggregator
    /// @param _index Stablecoin to get USD price for
    function getPriceFeed(uint256 _index)
        internal
        view
        returns (uint256, bool)
    {
        (, int256 answer, , uint256 updatedAt, ) = AggregatorV3Interface(
            getAggregator(_index)
        ).latestRoundData();
        return (uint256(answer), staleCheck(updatedAt));
    }

    function staleCheck(uint256 _updatedAt) internal view returns (bool) {
        return (block.timestamp - _updatedAt >= STALE_CHECK);
    }

    /// @notice Get USD/Stable coin chainlink feed
    /// @param _index index of feed based of stablecoin index (dai/usdc/usdt)
    function getAggregator(uint256 _index) public view returns (address) {
        if (_index >= NO_OF_AGGREGATORS) revert Errors.IndexTooHigh();
        if (_index == 0) {
            return daiUsdFeed;
        } else if (_index == 1) {
            return usdcUsdFeed;
        } else {
            return usdtUsdFeed;
        }
    }
}