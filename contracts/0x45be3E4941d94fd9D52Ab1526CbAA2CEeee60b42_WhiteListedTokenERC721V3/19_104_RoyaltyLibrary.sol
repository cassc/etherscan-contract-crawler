// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

library RoyaltyLibrary {
    enum Strategy {
        ROYALTY_STRATEGY, // get royalty from the sales price (default)
        PROFIT_DISTRIBUTION_STRATEGY, // profit sharing from a fixed royalties of the sales price
        PRIMARY_SALE_STRATEGY // 1 party get royalty from primary sale, secondary sale will follow ROYALTY_STRATEGY
    }

    struct RoyaltyInfo {
        uint256 value; //bps
        Strategy strategy;
    }

    struct RoyaltyShareDetails {
        address payable recipient;
        uint256 value; // bps
    }
}