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

    function processRoute(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        address to,
        bytes memory route
    ) external payable returns (uint256 amountOut);
}