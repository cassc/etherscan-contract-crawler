// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IFujiOracle
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface of the {FujiOracle}.
 */

interface IFujiOracle {
  /**
   * @dev Emit when a change in price feed address is done for an `asset`.
   *
   * @param asset address
   * @param newPriceFeedAddress that returns USD price from Chainlink
   */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  /**
   * @notice Returns the exchange rate between two assets, with price oracle given in
   * specified `decimals`.
   *
   * @param currencyAsset to be used, zero-address for USD
   * @param commodityAsset to be used, zero-address for USD
   * @param decimals  of the desired price output
   *
   * @dev Price format is defined as: (amount of currencyAsset per unit of commodityAsset Exchange Rate).
   * Requirements:
   * - Must check that both `currencyAsset` and `commodityAsset` are set in
   *   usdPriceFeeds, otherwise return zero.
   */
  function getPriceOf(
    address currencyAsset,
    address commodityAsset,
    uint8 decimals
  )
    external
    view
    returns (uint256);
}