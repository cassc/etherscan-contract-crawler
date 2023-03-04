// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct AssetFee {
    uint256 input; // position entry fee 1/10000
    uint256 output; // position exit fee 1/10000
}

struct FeeSettings {
    uint256 feeRoundIntervalHours;
    AssetFee asset1;
    AssetFee asset2;
}