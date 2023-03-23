// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library LimitOrder {

    struct Data {
        uint128 sellingX;
        uint128 earnY;
        uint256 accEarnY;
        uint256 legacyAccEarnY;
        uint128 legacyEarnY;
        uint128 sellingY;
        uint128 earnX;
        uint128 legacyEarnX;
        uint256 accEarnX;
        uint256 legacyAccEarnX;
    }

}