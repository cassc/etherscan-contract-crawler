// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

struct TradeDetails {
    uint256 marketId;
    uint256 value;
    bytes tradeData;
}

struct Marketplace {
    address proxy;
    bool isLib;
    bool isActive;
}