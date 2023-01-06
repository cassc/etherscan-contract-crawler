// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./XAssetInterface.sol";

interface XErrorInterface is XAssetInterface {
  // custom errors for XOracle
  error UnexpectedBatchID();
  error InvalidDataSigner();
  error MalformedData();
  error AssetNotFound(address tokenAddress, AssetType assetType);
  error DuplicatedAsset(address tokenAddress, AssetType assetType);
  error InconsistentBlockNumber();
  // custom errors for XAsset
  error ExceededStorageLimit(uint8 sizeLimit);
  error InvalidObservationTimestamp();
}