// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

enum SwapOrder {
    SELL,
    BUY
}

enum SwapDirection {
    INPUT,
    OUTPUT
}

struct SwapResult {
    bool isSwapped;
    uint256 amountIn;
    uint256 amountOut;
}