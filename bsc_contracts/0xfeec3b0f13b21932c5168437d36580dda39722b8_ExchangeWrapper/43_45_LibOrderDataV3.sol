// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibPart.sol";

library LibOrderDataV3 {
    bytes4 public constant V3_SELL = bytes4(keccak256("V3_SELL"));
    bytes4 public constant V3_BUY = bytes4(keccak256("V3_BUY"));

    struct DataV3_SELL {
        uint payouts;
        uint originFeeFirst;
        uint originFeeSecond;
        uint maxFeesBasePoint;
        bytes32 marketplaceMarker;
    }

    struct DataV3_BUY {
        uint payouts;
        uint originFeeFirst;
        uint originFeeSecond;
        bytes32 marketplaceMarker;
    }
}