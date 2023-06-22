// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../def/Shareholder.sol";
import "../def/TokenDiscount.sol";

struct ArtistContractConfig {
    string name;
    string symbol;
    address[] withdrawAdmins;
    address[] stateAdmins;
    address[] mintForFree;
    uint256 initialPrice;
    uint256 supplyCap;
    uint256 maxBatchSize;
    Shareholder[] shareholders;
    TokenDiscountInput[] tokenDiscounts;
}