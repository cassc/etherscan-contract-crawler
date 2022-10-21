// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol';
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';

import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import '@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol';
import '@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol';

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

/// @title Pool management functions
/// @notice Internal functions for managing liquidity and swaps in Uniswap V3
abstract contract PoolManagement is IUniswapV3MintCallback, IUniswapV3SwapCallback {
    address immutable internal uniswapFactory;

    struct PoolCallbackData {
        PoolAddress.PoolKey poolKey;
    }

    constructor(address _uniswapFactory) {
        uniswapFactory = _uniswapFactory;
    }

    /// @inheritdoc IUniswapV3MintCallback
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        PoolCallbackData memory decoded = abi.decode(data, (PoolCallbackData));
        CallbackValidation.verifyCallback(uniswapFactory, decoded.poolKey);

        if (amount0Owed > 0) TransferHelper.safeTransfer(decoded.poolKey.token0, msg.sender, amount0Owed);
        if (amount1Owed > 0) TransferHelper.safeTransfer(decoded.poolKey.token1, msg.sender, amount1Owed);
    }

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        PoolCallbackData memory decoded = abi.decode(data, (PoolCallbackData));
        CallbackValidation.verifyCallback(uniswapFactory, decoded.poolKey);

        if (amount0Delta > 0) TransferHelper.safeTransfer(decoded.poolKey.token0, msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) TransferHelper.safeTransfer(decoded.poolKey.token1, msg.sender, uint256(amount1Delta));
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(uniswapFactory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }

    struct AddLiquidityParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    function addLiquidity(AddLiquidityParams memory params)
        internal
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            IUniswapV3Pool pool
        )
    {
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: params.token0, token1: params.token1, fee: params.fee});

        pool = IUniswapV3Pool(PoolAddress.computeAddress(uniswapFactory, poolKey));

        // compute the liquidity amount
        {
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
            uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                params.amount0Desired,
                params.amount1Desired
            );
        }

        (amount0, amount1) = pool.mint(
            address(this),
            params.tickLower,
            params.tickUpper,
            liquidity,
            abi.encode(PoolCallbackData({poolKey: poolKey}))
        );

        require(amount0 >= params.amount0Min && amount1 >= params.amount1Min, 'Price slippage check');
    }

    function swapExactInputSingleInternal(        
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
        ) internal returns(uint256) {
        bool zeroForOne = tokenIn < tokenOut;

        PoolAddress.PoolKey memory poolKey =PoolAddress.getPoolKey(tokenIn, tokenOut, fee);

        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(uniswapFactory, poolKey));

        (int256 amount0, int256 amount1) =
            pool.swap(
                address(this),
                zeroForOne,
                int256(amountIn),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encode(PoolCallbackData({poolKey: poolKey}))
            );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }
}