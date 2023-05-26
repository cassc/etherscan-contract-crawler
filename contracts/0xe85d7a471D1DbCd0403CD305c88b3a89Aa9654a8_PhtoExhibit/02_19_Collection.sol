// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SaleStatus.sol";

/** 1 Phto. Collection */
struct Collection {
  /** Maximum mintable per tx */
  uint128 maxTx;
  /** Maximum tokens in collection */
  uint128 maxSupply;
  /** Percentage to be given from secondaries */
  uint128 royaltyPercentage;
  /** Current token supply */
  uint128 supply;
  /** Cost per token */
  uint256 cost;
  /** Receiving address of royalties */
  address royaltyReceiver;
  /** Base URI */
  string uri;
  /** Sale state */
  SaleStatus status;
}