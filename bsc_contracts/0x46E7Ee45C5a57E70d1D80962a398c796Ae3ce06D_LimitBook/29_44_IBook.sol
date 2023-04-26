// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IBook {
  struct OpenTradeInput {
    bytes32 priceId;
    address user;
    bool isBuy;
    uint128 margin;
    uint128 leverage;
    uint128 profitTarget;
    uint128 stopLoss;
    uint128 limitPrice;
  }

  struct CloseTradeInput {
    bytes32 orderHash;
    uint128 limitPrice;
    uint64 closePercent;
  }
}