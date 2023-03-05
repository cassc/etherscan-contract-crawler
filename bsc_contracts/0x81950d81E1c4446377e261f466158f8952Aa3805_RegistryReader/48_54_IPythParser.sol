// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IPythParser {
  struct PythInternalPriceInfo {
    // slot 1
    uint64 publishTime;
    int32 expo;
    int64 price;
    uint64 conf;
    // slot 2
    int64 emaPrice;
    uint64 emaConf;
    // extra
    bytes32 id;
  }

  function parsePriceFeedUpdates(
    bytes[] memory updateData,
    bytes32[] memory priceIds
  ) external view returns (PythInternalPriceInfo[] memory priceFeeds);
}