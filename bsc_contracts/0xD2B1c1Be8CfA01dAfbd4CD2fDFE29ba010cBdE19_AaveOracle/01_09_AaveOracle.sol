// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';

import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {IPriceFeed} from '../interfaces/IPriceFeed.sol';
import {SafeERC20} from '../dependencies/openzeppelin/contracts/SafeERC20.sol';

/// @title AaveOracle
/// @author Aave
/// @notice Proxy smart contract to get the price of an asset from a price source
contract AaveOracle is IPriceOracleGetter, Ownable {
  using SafeERC20 for IERC20;

  event AssetSourceUpdated(address indexed asset, address indexed source);

  mapping(address => IPriceFeed) private assetsSources;

  /// @notice Constructor
  /// @param assets The addresses of the assets
  /// @param sources The address of the source of each asset
  constructor(
    address[] memory assets,
    address[] memory sources
  ) {
    _setAssetsSources(assets, sources);
  }

  /// @notice External function called by the Aave governance to set or replace sources of assets
  /// @param assets The addresses of the assets
  /// @param sources The address of the source of each asset
  function setAssetSources(address[] calldata assets, address[] calldata sources)
    external
    onlyOwner
  {
    _setAssetsSources(assets, sources);
  }

  /// @notice Internal function to set the sources for each asset
  /// @param assets The addresses of the assets
  /// @param sources The address of the source of each asset
  function _setAssetsSources(address[] memory assets, address[] memory sources) internal {
    require(assets.length == sources.length, 'INCONSISTENT_PARAMS_LENGTH');
    for (uint256 i = 0; i < assets.length; i++) {
      assetsSources[assets[i]] = IPriceFeed(sources[i]);
      emit AssetSourceUpdated(assets[i], sources[i]);
    }
  }

  /// @notice Update an asset price by address
  /// @dev All assets are priced relative to USD
  /// @param asset The asset address
  function updateAssetPrice(address asset) public override returns (uint256) {
    IPriceFeed source = assetsSources[asset];
    return source.updatePrice();
  }

  /// @notice Gets an asset price by address
  /// @dev All assets are priced relative to USD
  /// @param asset The asset address
  function getAssetPrice(address asset) public view override returns (uint256) {
    IPriceFeed source = assetsSources[asset];
    return source.fetchPrice();
  }

  /// @notice Gets a list of prices from a list of assets addresses
  /// @param assets The list of assets addresses
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory) {
    uint256[] memory prices = new uint256[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      prices[i] = getAssetPrice(assets[i]);
    }
    return prices;
  }

  /// @notice Gets the address of the source for an asset address
  /// @param asset The address of the asset
  /// @return address The address of the source
  function getSourceOfAsset(address asset) external view returns (address) {
    return address(assetsSources[asset]);
  }

}