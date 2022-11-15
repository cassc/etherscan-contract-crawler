// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IDodoRouter {
    function dodoSwapV2TokenToETH(
        address fromToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 amountOut);

    function dodoSwapV2ETHToToken(
        address toToken,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 direction,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 amountOut);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 amountOut);
}