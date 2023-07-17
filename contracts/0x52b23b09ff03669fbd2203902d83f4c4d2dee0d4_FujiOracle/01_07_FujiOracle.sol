// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title FujiOracle
 * @author Fujidao Labs
 *
 * @notice Contract that returns and computes prices for the Fuji protocol
 * using Chainlink as the standard oracle to view latest price.
 */

import {SystemAccessControl} from "./access/SystemAccessControl.sol";
import {IAggregatorV3} from "./interfaces/chainlink/IAggregatorV3.sol";
import {IFujiOracle} from "./interfaces/IFujiOracle.sol";

contract FujiOracle is IFujiOracle, SystemAccessControl {
  error FujiOracle__lengthMismatch();
  error FujiOracle__noZeroAddress();
  error FujiOracle__noPriceFeed();
  error FujiOracle_invalidPriceFeedDecimals(address priceFeed);

  ///@notice Mapping from asset address to its Chainlink price feed oracle address.
  mapping(address => address) public usdPriceFeeds;

  /**
   * @notice Constructor of a new {FujiOracle}.
   * Requirements:
   * - Must provide some initial assets and price feed information.
   * - Must check `assets` and `priceFeeds` array match in size.
   * - Must ensure `priceFeeds` addresses return feed in USD formatted to 8 decimals.
   *
   * @param assets array of addresses
   * @param priceFeeds array of Chainlink contract addresses
   */
  constructor(
    address[] memory assets,
    address[] memory priceFeeds,
    address chief_
  )
    SystemAccessControl(chief_)
  {
    if (assets.length != priceFeeds.length) {
      revert FujiOracle__lengthMismatch();
    }

    for (uint256 i = 0; i < assets.length; i++) {
      _validatePriceFeedDecimals(priceFeeds[i]);
      usdPriceFeeds[assets[i]] = priceFeeds[i];
    }
  }

  /**
   * @notice Sets '_priceFeed' address for a '_asset'.
   * Requirements:
   * - Must only be called by a timelock.
   * - Must emits a {AssetPriceFeedChanged} event.
   * - Must ensure `priceFeed` addresses returns feed in USD formatted to 8 decimals.
   *
   * @param asset address
   * @param priceFeed Chainlink contract address
   */
  function setPriceFeed(address asset, address priceFeed) public onlyTimelock {
    if (priceFeed == address(0)) {
      revert FujiOracle__noZeroAddress();
    }

    _validatePriceFeedDecimals(priceFeed);

    usdPriceFeeds[asset] = priceFeed;
    emit AssetPriceFeedChanged(asset, priceFeed);
  }

  /// @inheritdoc IFujiOracle
  function getPriceOf(
    address currencyAsset,
    address commodityAsset,
    uint8 decimals
  )
    external
    view
    override
    returns (uint256 price)
  {
    price = 10 ** uint256(decimals);

    if (commodityAsset != address(0)) {
      price = price * _getUSDPrice(commodityAsset);
    } else {
      price = price * (10 ** 8);
    }

    if (currencyAsset != address(0)) {
      uint256 currencyAssetPrice = _getUSDPrice(currencyAsset);
      price = currencyAssetPrice == 0 ? 0 : (price / currencyAssetPrice);
    } else {
      price = price / (10 ** 8);
    }
  }

  /**
   * @dev Returns the USD price of asset in a 8 decimal uint format.
   * * Requirements:
   * - Must check that `asset` are set in `usdPriceFeeds` otherwise
   *   return zero.
   *
   * @param asset: the asset address.
   */
  function _getUSDPrice(address asset) internal view returns (uint256 price) {
    if (usdPriceFeeds[asset] == address(0)) {
      revert FujiOracle__noPriceFeed();
    }

    (, int256 latestPrice,,,) = IAggregatorV3(usdPriceFeeds[asset]).latestRoundData();

    price = uint256(latestPrice);
  }

  function _validatePriceFeedDecimals(address priceFeed) internal view {
    if (IAggregatorV3(priceFeed).decimals() != 8) {
      revert FujiOracle_invalidPriceFeedDecimals(priceFeed);
    }
  }
}