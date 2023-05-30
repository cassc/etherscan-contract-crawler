// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

enum SaleType {
  CLAIM,
  EXCHANGE
}

struct Sale {
    uint8 id;
    SaleType saleType;
    uint256 mintCost;
    uint256 maxSupply;
}