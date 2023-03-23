// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IOracleProvider {
  struct PricePackage {
    uint128 ask;
    uint128 bid;
    uint256 publishTime;
  }

  function getLatestPrice(
    bytes32 priceId
  ) external view returns (PricePackage memory package);
}