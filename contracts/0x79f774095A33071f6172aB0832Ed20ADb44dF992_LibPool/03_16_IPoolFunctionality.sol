// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IPoolFunctionality {

    struct SwapData {
        uint112     amount_spend;
        uint112     amount_receive;
        address     orionpool_router;
        bool        is_exact_spend;
        bool        supportingFee;
        bool        isInContractTrade;
        bool        isSentETHEnough;
        bool        isFromWallet;
        address     asset_spend;
        address[]   path;
    }

    struct InternalSwapData {
        address user;
        uint256 amountIn;
        uint256 amountOut;
        address asset_spend;
        address[] path;
        bool isExactIn;
        address to;
        address curFactory;
        FactoryType curFactoryType;
        bool supportingFee;
    }

    enum FactoryType {
        UNSUPPORTED,
        UNISWAPLIKE,
        CURVE
    }

    function doSwapThroughOrionPool(
        address user,
        address to,
        IPoolFunctionality.SwapData calldata swapData
    ) external returns (uint amountOut, uint amountIn);

    function getWETH() external view returns (address);

    function addLiquidityFromExchange(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function isFactory(address a) external view returns (bool);

    function isLending(address pool) external view returns (bool);
}