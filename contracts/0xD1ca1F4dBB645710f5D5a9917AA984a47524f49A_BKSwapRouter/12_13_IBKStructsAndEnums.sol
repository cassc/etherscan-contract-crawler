//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

struct OrderInfo{
    bytes transferId;
    uint dstChainId;
    address desireToken;
    address bridgeReceiver;
}

enum SwapType {
    FREE,
    ETH_TOKEN,
    TOKEN_ETH,
    TOKEN_TOKEN,
    TOKEN_TO_WHITE,
    WHITE_TO_TOKEN
}

struct SignParams {
    bytes32 nonceHash;
    bytes signature;
}

struct BasicParams {
    SignParams signParams;
    SwapType swapType;
    address fromTokenAddress;
    address toTokenAddress;
    uint amountInTotal;
    uint amountInForSwap;
    address receiver;
    uint minAmountOut;
}

struct AggregationParams {
    address approveTarget;
    address callTarget;
    bytes data;
}