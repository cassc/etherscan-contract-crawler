// SPDX-License-Identifier: GPL-3.0

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.15;

import { IPriceFeed } from './IPriceFeed.sol';
import { AggregatorV3Interface } from './AggregatorV3Interface.sol';
import { SafeCast } from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

/**
 * @notice Provides price data to {TokenBuyer}.
 */

/// @title PriceFeed
/// @notice Provides price data to `TokenBuyer` using a Chainlink price feed
contract PriceFeed is IPriceFeed {
    using SafeCast for int256;

    uint256 constant WAD_DECIMALS = 18;

    error StaleOracle(uint256 updatedAt);
    error InvalidPrice(uint256 priceWAD);

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      IMMUTABLES
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Chainlink price feed
    AggregatorV3Interface public immutable chainlink;

    /// @notice Number of decimals of the chainlink price feed answer
    uint8 public immutable decimals;

    /// @dev A factor to multiply or divide by to get to 18 decimals
    uint256 public immutable decimalFactor;

    /// @dev Max staleness allowed from chainlink, in seconds
    uint256 public immutable staleAfter;

    /// @dev Sanity check: minimal price allowed
    uint256 public immutable priceLowerBound;

    /// @dev Sanity check: maximal price allowed
    uint256 public immutable priceUpperBound;

    constructor(
        AggregatorV3Interface _chainlink,
        uint256 _staleAfter,
        uint256 _priceLowerBound,
        uint256 _priceUpperBound
    ) {
        chainlink = _chainlink;
        decimals = chainlink.decimals();
        staleAfter = _staleAfter;
        priceLowerBound = _priceLowerBound;
        priceUpperBound = _priceUpperBound;

        uint256 decimalFactorTemp = 1;
        if (decimals < WAD_DECIMALS) {
            decimalFactorTemp = 10**(WAD_DECIMALS - decimals);
        } else if (decimals > WAD_DECIMALS) {
            decimalFactorTemp = 10**(decimals - WAD_DECIMALS);
        }
        decimalFactor = decimalFactorTemp;
    }

    /// @notice Returns the price of ETH/Token by fetching from Chainlink
    /// @dev Explain to a developer any extra details
    /// @return The price is returned in WAD (18 decimals)
    function price() external view override returns (uint256) {
        (, int256 chainlinkPrice, , uint256 updatedAt, ) = chainlink.latestRoundData();

        if (updatedAt < block.timestamp - staleAfter) {
            revert StaleOracle(updatedAt);
        }

        uint256 priceWAD = toWAD(chainlinkPrice.toUint256());

        if (priceWAD < priceLowerBound || priceWAD > priceUpperBound) {
            revert InvalidPrice(priceWAD);
        }
        return priceWAD;
    }

    /// @dev convert price to 18 decimals
    function toWAD(uint256 chainlinkPrice) internal view returns (uint256) {
        if (decimals == WAD_DECIMALS) {
            return chainlinkPrice;
        } else if (decimals < WAD_DECIMALS) {
            return chainlinkPrice * decimalFactor;
        } else {
            return chainlinkPrice / decimalFactor;
        }
    }
}