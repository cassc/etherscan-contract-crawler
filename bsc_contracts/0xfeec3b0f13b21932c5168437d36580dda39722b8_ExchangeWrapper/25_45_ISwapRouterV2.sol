// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface ISwapRouterV2 {
    // regular
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMinimum,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMaximum,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMinimum,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint amountOut);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMaximum,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMinimum,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    // avalanche
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMinimum,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMaximum,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactAVAXForTokens(
        uint amountOutMinimum,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint amountOut);

    function swapTokensForExactAVAX(
        uint amountOut,
        uint amountInMaximum,
        uint[] calldata binSteps,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForAVAX(
        uint amountIn,
        uint amountOutMinimum,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapAVAXForExactTokens(
        uint amountOut,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}