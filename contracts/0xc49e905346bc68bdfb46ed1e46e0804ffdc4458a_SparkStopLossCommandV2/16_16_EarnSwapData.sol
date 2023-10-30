// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
struct SwapData {
    address fromAsset;
    address toAsset;
    uint256 amount;
    uint256 receiveAtLeast;
    uint256 fee;
    bytes withData;
    bool collectFeeInFromToken;
}

library EarnSwapData {}