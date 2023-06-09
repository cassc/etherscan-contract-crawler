// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface ICryptoPoolAdapter {

    function addLiquidity(
        address pool,
        uint256 amountIn,
        uint256 coinIndex,
        address to,
        uint256 minAmountOut,
        address emergencyTo
    ) external returns(uint256 amountOut);

    function swap(
        address tokenIn,
        address pool,
        uint256 i,
        uint256 j,
        address tokenOut,
        address to,
        uint256 minAmountOut,
        address emergencyTo,
        uint256 aggregationFee
    ) external returns(uint256 amountOut);

    function removeLiquidity(
        address pool,
        uint256 i,
        address to,
        address tokenOut,
        uint256 minAmountOut,
        address emergencyTo
    ) external  returns(uint256 amountOut);
}