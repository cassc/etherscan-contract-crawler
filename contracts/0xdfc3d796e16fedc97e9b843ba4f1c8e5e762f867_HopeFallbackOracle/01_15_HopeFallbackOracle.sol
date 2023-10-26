// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {AggregatorInterface} from './dependencies/chainlink/AggregatorInterface.sol';
import {Errors} from './libraries/Errors.sol';
import {HopeOneRole} from './access/HopeOneRole.sol';
import {IHopeFallbackOracle} from './interfaces/IHopeFallbackOracle.sol';

/**
 * @title HopeFallbackOracle
 * @author Hope
 * @notice Contract to get asset prices, manage price sources
 * - Use of Chainlink Aggregators as first source of price
 * - Owned by the Hope governance
 */
contract HopeFallbackOracle is IHopeFallbackOracle, HopeOneRole {
  // Map of asset price sources (asset => AggregatorInterface)
  mapping(address => AggregatorInterface) private assetsSources;

  address public immutable override BASE_CURRENCY;
  uint256 public immutable override BASE_CURRENCY_UNIT;

  /**
   * @notice Constructor
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   * @param baseCurrency The base currency used for the price quotes. If USD is used, base currency is 0x0
   * @param baseCurrencyUnit The unit of the base currency
   */
  constructor(address[] memory assets, address[] memory sources, address baseCurrency, uint256 baseCurrencyUnit) {
    _setAssetsSources(assets, sources);
    BASE_CURRENCY = baseCurrency;
    BASE_CURRENCY_UNIT = baseCurrencyUnit;
    emit BaseCurrencySet(baseCurrency, baseCurrencyUnit);
  }

  /// @inheritdoc IHopeFallbackOracle
  function setAssetSources(
    address[] calldata assets,
    address[] calldata sources
  ) external override onlyRole(OPERATOR_ROLE) {
    _setAssetsSources(assets, sources);
  }

  /**
   * @notice Internal function to set the sources for each asset
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   */
  function _setAssetsSources(address[] memory assets, address[] memory sources) internal {
    require(assets.length == sources.length, Errors.INCONSISTENT_PARAMS_LENGTH);
    for (uint256 i = 0; i < assets.length; i++) {
      assetsSources[assets[i]] = AggregatorInterface(sources[i]);
      emit AssetSourceUpdated(assets[i], sources[i]);
    }
  }

  function getAssetPrice(address asset) public view override returns (uint256) {
    AggregatorInterface source = assetsSources[asset];

    if (asset == BASE_CURRENCY) {
      return BASE_CURRENCY_UNIT;
    } else {
      int256 price = source.latestAnswer();
      return uint256(price);
    }
  }

  /// @inheritdoc IHopeFallbackOracle
  function getAssetsPrices(address[] calldata assets) external view override returns (uint256[] memory) {
    uint256[] memory prices = new uint256[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      prices[i] = getAssetPrice(assets[i]);
    }
    return prices;
  }

  /// @inheritdoc IHopeFallbackOracle
  function getSourceOfAsset(address asset) external view override returns (address) {
    return address(assetsSources[asset]);
  }
}