// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibPart.sol";
import "./LibAsset.sol";
import "./LibFeeSide.sol";

library LibDeal {
    struct DealSide {
        LibAsset.Asset asset;
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
        address proxy;
        address from;
    }

    struct DealData {
        uint maxFeesBasePoint;
        LibFeeSide.FeeSide feeSide;
    }
}