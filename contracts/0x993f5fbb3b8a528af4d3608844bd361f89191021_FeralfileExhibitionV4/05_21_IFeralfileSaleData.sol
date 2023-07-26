// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFeralfileSaleData {
    struct RevenueShare {
        address recipient;
        uint256 bps;
    }

    struct SaleData {
        uint256 price; // in wei
        uint256 cost; // in wei
        uint256 expiryTime;
        address destination;
        uint256[] tokenIds;
        RevenueShare[][] revenueShares; // address and royalty bps (500 means 5%)
        bool payByVaultContract; // get eth from vault contract, used by credit card pay that proxy by ITX
    }
}