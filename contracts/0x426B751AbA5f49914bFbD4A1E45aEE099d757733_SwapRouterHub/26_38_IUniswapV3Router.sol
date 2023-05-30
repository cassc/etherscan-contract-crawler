// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IUniswapV3Router {
    struct UniswapV3ExactInputSingleParameters {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;

    function uniswapV3ExactInputSingle(
        UniswapV3ExactInputSingleParameters calldata parameters
    ) external payable returns (uint256 amountOut);

    struct UniswapV3ExactInputParameters {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function uniswapV3ExactInput(
        UniswapV3ExactInputParameters calldata parameters
    ) external payable returns (uint256 amountOut);

    struct UniswapV3ExactOutputSingleParameters {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function uniswapV3ExactOutputSingle(
        UniswapV3ExactOutputSingleParameters calldata parameters
    ) external payable returns (uint256 amountIn);

    struct UniswapV3ExactOutputParameters {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function uniswapV3ExactOutput(
        UniswapV3ExactOutputParameters calldata parameters
    ) external payable returns (uint256 amountIn);
}