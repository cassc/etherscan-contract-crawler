// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

enum SaleType {
  CLAIM,
  EXCHANGE
}

struct Sale {
    uint8 id;
    uint248 mintCost;
    uint248 maxSupply;
    SaleType saleType;
}