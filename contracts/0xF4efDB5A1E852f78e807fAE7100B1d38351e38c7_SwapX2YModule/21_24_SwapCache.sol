// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

// group local vars in swap functions to avoid stack too deep
struct SwapCache {
    // fee growth of tokenX during swap
    uint256 currFeeScaleX_128;
    // fee growth of tokenY during swap
    uint256 currFeeScaleY_128;
    // whether swap finished
    bool finished;
    // 96bit-fixpoint of sqrt(1.0001)
    uint160 _sqrtRate_96;
    // pointDelta
    int24 pointDelta;
    // whether has limorder and whether as endpt for current point
    int24 currentOrderOrEndpt;
    // start point of swap, etc. state.currPt before swap loop
    int24 startPoint;
    // start liquidity of swap, etc. state.liquidity before swap loop
    uint128 startLiquidity;
    // block time stamp of this swap transaction
    uint32 timestamp;
}