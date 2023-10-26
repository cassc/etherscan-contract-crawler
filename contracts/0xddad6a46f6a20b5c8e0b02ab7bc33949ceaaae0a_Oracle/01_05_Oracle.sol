//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAggregator.sol";
import './interfaces/IOracle.sol';

/**
 * @title Oracle
 * @author LC
 * @notice Contract to get asset prices, manage price sources
 */
contract Oracle is IOracle, Ownable {

  // Map of asset price sources (asset => priceSource)
  mapping(address => IAggregator) private assetsSources;

  /**
   * @notice Constructor
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   */
  constructor(
    address[] memory assets,
    address[] memory sources
  ) {
    _setAssetsSources(assets, sources);
  }

  function setAssetSources(
    address[] calldata assets,
    address[] calldata sources
  ) external override onlyOwner {
    _setAssetsSources(assets, sources);
  }

  /**
   * @notice Internal function to set the sources for each asset
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   */
  function _setAssetsSources(address[] memory assets, address[] memory sources) internal {
    require(assets.length == sources.length, "Array parameters should be equal");
    for (uint256 i = 0; i < assets.length; i++) {
      assetsSources[assets[i]] = IAggregator(sources[i]);
      emit AssetSourceUpdated(assets[i], sources[i]);
    }
  }

  function getAssetPrice(address asset) public view override returns (uint256) {
    IAggregator source = assetsSources[asset];

    if (address(source) == address(0)) {
      return 0;
    }

    (
      /* uint80 roundID */,
      int price,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = source.latestRoundData();

    return uint256(price);
  }

  function getAssetsPrices(
    address[] calldata assets
  ) external view override returns (uint256[] memory) {
    uint256[] memory prices = new uint256[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      prices[i] = getAssetPrice(assets[i]);
    }
    return prices;
  }

  function getSourceOfAsset(address asset) external view override returns (address) {
    return address(assetsSources[asset]);
  }
}