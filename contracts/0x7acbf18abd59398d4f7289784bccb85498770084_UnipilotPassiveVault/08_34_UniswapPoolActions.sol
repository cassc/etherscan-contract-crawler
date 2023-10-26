// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./SafeCastExtended.sol";
import "./UniswapLiquidityManagement.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";

/// @title Liquidity and ticks functions
/// @notice Provides functions for computing liquidity and ticks for token amounts and prices
library UniswapPoolActions {
    using LowGasSafeMath for uint256;
    using SafeCastExtended for uint256;
    using UniswapLiquidityManagement for IUniswapV3Pool;

    function updatePosition(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper
    ) internal returns (uint128 liquidity) {
        (liquidity, , ) = pool.getPositionLiquidity(tickLower, tickUpper);

        if (liquidity > 0) {
            pool.burn(tickLower, tickUpper, 0);
        }
    }

    function burnLiquidity(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        address recipient
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fees0,
            uint256 fees1
        )
    {
        (uint128 liquidity, , ) = pool.getPositionLiquidity(
            tickLower,
            tickUpper
        );
        if (liquidity > 0) {
            (amount0, amount1) = pool.burn(tickLower, tickUpper, liquidity);
            if (amount0 > 0 || amount1 > 0) {
                (uint256 collect0, uint256 collect1) = pool.collect(
                    recipient,
                    tickLower,
                    tickUpper,
                    type(uint128).max,
                    type(uint128).max
                );

                (fees0, fees1) = (collect0.sub(amount0), collect1.sub(amount1));
            }
        }
    }

    function burnUserLiquidity(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 userSharePercentage,
        address recipient
    ) internal returns (uint256 amount0, uint256 amount1) {
        (uint128 liquidity, , ) = pool.getPositionLiquidity(
            tickLower,
            tickUpper
        );

        uint256 liquidityRemoved = FullMath.mulDiv(
            uint256(liquidity),
            userSharePercentage,
            1e18
        );

        (amount0, amount1) = pool.burn(
            tickLower,
            tickUpper,
            liquidityRemoved.toUint128()
        );

        if (amount0 > 0 || amount1 > 0) {
            (amount0, amount0) = pool.collect(
                recipient,
                tickLower,
                tickUpper,
                amount0.toUint128(),
                amount1.toUint128()
            );
        }
    }

    function mintLiquidity(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint128 liquidity = pool.getLiquidityForAmounts(
            amount0Desired,
            amount1Desired,
            tickLower,
            tickUpper
        );

        if (liquidity > 0) {
            (amount0, amount1) = pool.mint(
                address(this),
                tickLower,
                tickUpper,
                liquidity,
                abi.encode(address(this))
            );
        }
    }

    function swapToken(
        IUniswapV3Pool pool,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified
    ) internal {
        (uint160 sqrtPriceX96, , ) = pool.getSqrtRatioX96AndTick();

        uint160 exactSqrtPriceImpact = (sqrtPriceX96 * (1e5 / 2)) / 1e6;

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? sqrtPriceX96 - exactSqrtPriceImpact
            : sqrtPriceX96 + exactSqrtPriceImpact;

        pool.swap(
            recipient,
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            abi.encode(zeroForOne)
        );
    }

    function collectPendingFees(
        IUniswapV3Pool pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper
    ) internal returns (uint256 collect0, uint256 collect1) {
        updatePosition(pool, tickLower, tickUpper);

        (collect0, collect1) = pool.collect(
            recipient,
            tickLower,
            tickUpper,
            type(uint128).max,
            type(uint128).max
        );
    }

    function rerangeLiquidity(
        IUniswapV3Pool pool,
        int24 baseThreshold,
        int24 tickSpacing,
        uint256 balance0,
        uint256 balance1
    ) internal returns (int24 tickLower, int24 tickUpper) {
        (tickLower, tickUpper) = pool.getPositionTicks(
            balance0,
            balance1,
            baseThreshold,
            tickSpacing
        );

        mintLiquidity(pool, tickLower, tickUpper, balance0, balance1);
    }
}