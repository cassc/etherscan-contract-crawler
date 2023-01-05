// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableTradingPairMap.sol";

interface DenominationsInterface {
  function totalPairsAvailable() external view returns (uint256);

  function getAllPairs() external view returns (EnumerableTradingPairMap.Pair[] memory);

  function getTradingPairDetails(string calldata base, string calldata quote)
    external
    view
    returns (
      address,
      address,
      address
    );

  function insertPair(
    string calldata base,
    string calldata quote,
    address baseAssetAddress,
    address quoteAssetAddress,
    address feedAdapterAddress
  ) external;

  function removePair(string calldata base, string calldata quote) external;

  function exists(string calldata base, string calldata quote) external view returns (bool);
}