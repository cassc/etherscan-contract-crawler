// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract ILiquidityPool {
    address public token0;
    address public token1;

    // Not marked `view` to allow calls to Uniswap Quoter, which is
    // gas inefficient. Do not call on-chain.
    function previewSwap(address tokenIn,
                         uint128 amountIn,
                         uint128 sqrtPriceLimitX96) virtual external returns (uint256, uint256);

    function previewSwapOut(address tokenIn,
                            uint128 amountOut,
                            uint128 sqrtPriceLimitX96) virtual external returns (uint256, uint256);

    function swap(address recipient,
                  address tokenIn,
                  uint128 amountIn,
                  uint128 amountOutMinimum,
                  uint128 sqrtPriceLimitX96)
        virtual external returns (uint256);
}