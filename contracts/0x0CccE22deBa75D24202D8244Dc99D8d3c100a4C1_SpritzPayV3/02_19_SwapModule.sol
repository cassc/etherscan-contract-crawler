// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/// @title Interface for SwapModule
interface SwapModule {
    struct ExactOutputParams {
        address to;
        address from;
        uint256 inputTokenAmountMax;
        uint256 paymentTokenAmount;
        uint256 deadline;
        bytes swapData;
    }

    function exactOutputNativeSwap(ExactOutputParams calldata swapParams) external payable returns (uint256);

    function exactOutputSwap(ExactOutputParams calldata swapParams) external returns (uint256);

    function decodeSwapData(bytes calldata swapData) external returns (address, address);
}