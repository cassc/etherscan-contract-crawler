// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

interface IRouteProcessor {
    
    struct RouteProcessorData {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 amountOutMin;
        address to;
        bytes route;
    }
    
    /// @notice Process a swap with passed route on RouteProcessor
    /// @param tokenIn The address of the token to swap from
    /// @param amountIn The amount of token to swap from
    /// @param tokenOut The address of the token to swap to
    /// @param amountOutMin The minimum amount of token to receive
    /// @param to The address to send the swapped token to
    /// @param route The route to use for the swap
    function processRoute(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        address to,
        bytes memory route
    ) external payable returns (uint256 amountOut);
}