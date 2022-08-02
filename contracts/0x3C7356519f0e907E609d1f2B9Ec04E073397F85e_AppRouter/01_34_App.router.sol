//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../interfaces/IUniswapV2Callee.sol";
import "../base/Withdraw.sol";
import "./SwapSushiAndV2.sol";
import "./SwapSushiAndV3.sol";
import "./SwapV2AndV3.sol";

contract AppRouter is
    IUniswapV2Callee,
    IUniswapV3SwapCallback,
    SwapSushiAndV2Router,
    SwapSushiAndV3Router,
    SwapV2AndV3Router,
    Withdraw
{
    event AccountLog(uint256 amount);

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        (
            uint256 amountIn,
            uint8 swapType,
            uint24 fee,
            uint256 payETHToCoinbase
        ) = abi.decode(data, (uint256, uint8, uint24, uint256));
        // swapType枚举值
        // 1: uniswapV2 -> sushi的回调
        // 2: sushi -> uniswapV2的回调
        // 3: uniswapV2 -> uniswapV3的回调
        // 4: sushi -> uniswapV3的回调
        if (swapType == 1) {
            uniswapV2ForSushiCallback(
                amountIn,
                amount0,
                amount1,
                payETHToCoinbase
            );
        }
        if (swapType == 2) {
            sushiForUniswapV2CallBack(
                amountIn,
                amount0,
                amount1,
                payETHToCoinbase
            );
        }
        if (swapType == 3) {
            sushiForUniswapV3Callback(
                amountIn,
                amount0,
                amount1,
                payETHToCoinbase,
                fee
            );
        }
        if (swapType == 4) {
            uniswapV2ForUniswapV3Callback(
                amountIn,
                amount0,
                amount1,
                payETHToCoinbase,
                fee
            );
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        (
            uint256 amountIn,
            address token,
            uint8 swapType,
            uint256 payETHToCoinbase
        ) = abi.decode(data, (uint256, address, uint8, uint256));

        if (swapType == 5) {
            uniswapV3ForSushiCallback(
                amount0Delta,
                amount1Delta,
                token,
                amountIn,
                payETHToCoinbase
            );
        }
        if (swapType == 6) {
            uniswapV3ForV2Callback(
                amount0Delta,
                amount1Delta,
                token,
                amountIn,
                payETHToCoinbase
            );
        }
    }

    // 回调函数，避免被重入攻击
    receive() external payable {
        emit AccountLog(msg.value);
    }
}