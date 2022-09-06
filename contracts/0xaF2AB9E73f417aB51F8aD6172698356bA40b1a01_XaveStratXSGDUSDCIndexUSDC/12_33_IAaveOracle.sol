// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

interface IAaveOracle {
  function BASE_CURRENCY (  ) external view returns ( address );
  function BASE_CURRENCY_UNIT (  ) external view returns ( uint256 );
  function getAssetPrice ( address asset ) external view returns ( uint256 );
  function getAssetsPrices ( address[] memory assets ) external view returns ( uint256[] memory);
  function getFallbackOracle (  ) external view returns ( address );
  function getSourceOfAsset ( address asset ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function setAssetSources ( address[] memory assets, address[] memory sources ) external;
  function setFallbackOracle ( address fallbackOracle ) external;
  function transferOwnership ( address newOwner ) external;
}