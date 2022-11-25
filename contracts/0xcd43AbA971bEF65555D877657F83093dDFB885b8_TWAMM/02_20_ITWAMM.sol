// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

interface ITWAMM {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function obtainReserves(
        address token0,
        address token1
    ) external view returns (uint256 reserve0, uint256 reserve1);

    function obtainTotalSupply(
        address token0,
        address token1
    ) external view returns (uint256);

    function obtainPairAddress(
        address token0,
        address token1
    ) external view returns (address);

    function createPairWrapper(
        address token0,
        address token1,
        uint256 deadline
    ) external returns (address pair);

    function addInitialLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 deadline
    ) external returns (uint256 lpTokenAmount);

    function addInitialLiquidityETH(
        address token,
        uint256 amountToken,
        uint256 amountETH,
        uint256 deadline
    ) external payable returns (uint256 lpTokenAmount);

    function addLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 amountIn0Max,
        uint256 amountIn1Max,
        uint256 deadline
    ) external returns (uint256 amountIn0, uint256 amountIn1);

    function addLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 amountTokenInMax,
        uint256 amountETHInMax,
        uint256 deadline
    ) external payable returns (uint256 amountTokenIn, uint256 amountETHIn);

    function withdrawLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 amountOut0Min,
        uint256 amountOut1Min,
        uint256 deadline
    ) external returns (uint256 amountOut0, uint256 amountOut1);

    function withdrawLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 amountTokenOutMin,
        uint256 amountETHOutMin,
        uint256 deadline
    ) external returns (uint256 amountTokenOut, uint256 amountETHOut);

    function instantSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function instantSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 amountETHOutMin,
        uint256 deadline
    ) external returns (uint256 amountETHOut);

    function instantSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 amountTokenOutMin,
        uint256 deadline
    ) external payable returns (uint256 amountTokenOut);

    function longTermSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external returns (uint256 orderId);

    function longTermSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external returns (uint256 orderId);

    function longTermSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external payable returns (uint256 orderId);

    function cancelTermSwapTokenToToken(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 unsoldAmount, uint256 purchasedAmount);

    function cancelTermSwapTokenToETH(
        address token,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 unsoldTokenAmount, uint256 purchasedETHAmount);

    function cancelTermSwapETHToToken(
        address token,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 unsoldETHAmount, uint256 purchasedTokenAmount);

    function withdrawProceedsFromTermSwapTokenToToken(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 proceeds);

    function withdrawProceedsFromTermSwapTokenToETH(
        address token,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 proceedsETH);

    function withdrawProceedsFromTermSwapETHToToken(
        address token,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 proceedsToken);

    function executeVirtualOrdersWrapper(
        address pair,
        uint256 blockNumber
    ) external;
}