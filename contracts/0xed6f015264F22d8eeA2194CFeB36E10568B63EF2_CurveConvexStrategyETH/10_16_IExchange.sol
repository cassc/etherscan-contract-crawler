// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IExchange {
    struct RouteEdge {
        uint32 swapProtocol; // 0 - unknown edge, 1 - UniswapV2, 2 - Curve...
        address pool; // address of pool to call
        address fromCoin; // address of coin to deposit to pool
        address toCoin; // address of coin to get from pool
    }
    struct LpToken {
        uint32 swapProtocol; // 0 - unknown edge, 1 - UniswapV2, 2 - Curve...
        address pool; // address of pool to call
    }
    function exchange(
        address from,
        address to,
        uint256 amountIn,
        uint256 minAmountOut
    ) external payable returns (uint256);

    function createInternalMajorRoutes(RouteEdge[][] calldata routes) external;
    function createLpToken(
        LpToken[] calldata edges,
        address[] calldata lpTokensAddress,
        address[][] calldata entryCoins
    ) external;

    function createApproval(
        address[] calldata coins,
        address[] calldata spenders
    ) external;
    function registerAdapters(
        address[] calldata adapters_,
        uint32[] calldata protocolId
    ) external;
    function createMinorCoinEdge(RouteEdge[] calldata edges) external;

}