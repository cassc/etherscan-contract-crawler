// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct CurrencyPrice {
    uint248 value;
    bool dynamicPricing;
    address externalAddress;
    address currency;
}