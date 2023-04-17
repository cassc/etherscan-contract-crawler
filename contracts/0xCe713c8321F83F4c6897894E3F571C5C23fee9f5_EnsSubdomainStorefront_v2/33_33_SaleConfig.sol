// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct SaleConfig {
    address owner;
    uint88 price; // max value is 309,485,009 dollar
    bool isForSale;
    uint256 dailyRent;
}