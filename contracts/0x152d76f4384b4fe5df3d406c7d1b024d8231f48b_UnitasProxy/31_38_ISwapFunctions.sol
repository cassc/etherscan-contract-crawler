// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface ISwapFunctions {
    enum AmountType {
        In,
        Out
    }

    struct SwapRequest {
        AmountType amountType;
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint256 feeNumerator;
        uint256 feeBase;
        address feeToken;
        uint256 price;
        uint256 priceBase;
        address quoteToken;
    }
}