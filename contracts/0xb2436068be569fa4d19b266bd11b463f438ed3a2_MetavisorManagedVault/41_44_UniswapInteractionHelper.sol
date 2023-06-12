// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import { SqrtPriceMath } from "@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol";
import { PositionKey } from "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";
import { LiquidityAmounts } from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

import { Errors } from "./Errors.sol";
import { DENOMINATOR } from "../MetavisorRegistry.sol";

uint256 constant PRECISION_FACTOR = 1e36;
uint256 constant X96 = 2 ** (96 * 2);

uint160 constant PRICE_IMPACT_DENOMINATOR = 100_0000;

struct TicksData {
    int24 tickLower;
    int24 tickUpper;
}

library UniswapInteractionHelper {
    /*
     ** Primary Interactions
     */
    function burnLiquidity(
        IUniswapV3Pool pool,
        TicksData memory ticks,
        uint256 shares,
        uint256 totalSupply,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amount0, uint256 amount1, uint256 fees0, uint256 fees1) {
        (uint128 liquidity, , ) = getLiquidityInPosition(pool, ticks);

        uint256 liquidityToRemove = shares == type(uint256).max
            ? liquidity
            : FullMath.mulDiv(liquidity, shares, totalSupply);

        if (liquidity > 0) {
            (amount0, amount1) = pool.burn(
                ticks.tickLower,
                ticks.tickUpper,
                uint128(liquidityToRemove)
            );
            if (amount0 < amount0Min || amount1 < amount1Min) {
                revert Errors.InvalidLiquidityOperation();
            }

            // Always collects all fee.
            (uint256 collect0, uint256 collect1) = pool.collect(
                address(this),
                ticks.tickLower,
                ticks.tickUpper,
                type(uint128).max,
                type(uint128).max
            );

            (fees0, fees1) = (collect0 - amount0, collect1 - amount1);
        }
    }

    function mintLiquidity(
        IUniswapV3Pool pool,
        TicksData memory ticks,
        uint256 amount0Input,
        uint256 amount1Input,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint128 liquidity = getLiquidityForAmounts(pool, amount0Input, amount1Input, ticks);

        if (liquidity > 0) {
            (amount0, amount1) = pool.mint(
                address(this),
                ticks.tickLower,
                ticks.tickUpper,
                liquidity,
                ""
            );
            if (amount0 < amount0Min || amount1 < amount1Min) {
                revert Errors.InvalidLiquidityOperation();
            }
        }
    }

    function swapToken(
        IUniswapV3Pool pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 maxPriceImpact
    ) internal {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        uint160 maxSqrtPriceImpact = (sqrtPriceX96 * maxPriceImpact) / PRICE_IMPACT_DENOMINATOR;

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? sqrtPriceX96 - maxSqrtPriceImpact
            : sqrtPriceX96 + maxSqrtPriceImpact;

        pool.swap(address(this), zeroForOne, amountSpecified, sqrtPriceLimitX96, "");
    }

    /*
     ** Secondary Interactions
     */
    function getAmountsForLiquidity(
        IUniswapV3Pool pool,
        uint128 liquidity,
        TicksData memory ticks
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(ticks.tickLower),
                TickMath.getSqrtRatioAtTick(ticks.tickUpper),
                liquidity
            );
    }

    function getLiquidityForAmounts(
        IUniswapV3Pool pool,
        uint256 amount0,
        uint256 amount1,
        TicksData memory ticks
    ) internal view returns (uint128 liquidity) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(ticks.tickLower),
                TickMath.getSqrtRatioAtTick(ticks.tickUpper),
                amount0,
                amount1
            );
    }

    function computeShares(
        IUniswapV3Pool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 balance0,
        uint256 balance1,
        uint256 totalSupply,
        TicksData memory ticks
    ) internal returns (uint256 shares) {
        (uint256 amount0, uint256 amount1, uint256 fees0, uint256 fees1, ) = getReserves(
            pool,
            ticks
        );

        uint256 reserve0 = amount0 + fees0 + balance0;
        uint256 reserve1 = amount1 + fees1 + balance1;

        if (totalSupply > 0) {
            assert(reserve0 != 0 || reserve1 != 0);
        }

        (, int24 currentTick, , , , , ) = pool.slot0();
        uint256 price = FullMath.mulDiv(
            uint256(TickMath.getSqrtRatioAtTick(currentTick)) ** 2,
            PRECISION_FACTOR,
            X96
        );

        shares = amount1Max + ((amount0Max * price) / PRECISION_FACTOR);

        if (totalSupply != 0) {
            uint256 reserve0PricedInToken1 = (reserve0 * price) / PRECISION_FACTOR;
            shares = (shares * totalSupply) / (reserve0PricedInToken1 + reserve1);
        }
    }

    /*
     ** Tertiary Interactions
     */
    function pokePosition(
        IUniswapV3Pool pool,
        TicksData memory ticks
    ) internal returns (uint128 liquidity) {
        (liquidity, , ) = getLiquidityInPosition(pool, ticks);

        if (liquidity > 0) {
            pool.burn(ticks.tickLower, ticks.tickUpper, 0);
        }
    }

    function getLiquidityInPosition(
        IUniswapV3Pool pool,
        TicksData memory ticks
    ) internal view returns (uint128 liquidity, uint128 tokensOwed0, uint128 tokensOwed1) {
        bytes32 positionKey = PositionKey.compute(address(this), ticks.tickLower, ticks.tickUpper);

        (liquidity, , , tokensOwed0, tokensOwed1) = pool.positions(positionKey);
    }

    function isTwapWithinThreshold(
        IUniswapV3Pool pool,
        uint32 _twapInterval,
        uint256 _priceThreshold
    ) public view returns (bool withinRange) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 priceCurren = FullMath.mulDiv(uint256(sqrtPriceX96) ** 2, PRECISION_FACTOR, X96);

        uint160 sqrtPriceBefore = getSqrtRatioX96AtInterval(pool, _twapInterval);
        uint256 priceBefore = FullMath.mulDiv(uint256(sqrtPriceBefore) ** 2, PRECISION_FACTOR, X96);

        if (
            (priceCurren * DENOMINATOR) / priceBefore > _priceThreshold ||
            (priceBefore * DENOMINATOR) / priceCurren > _priceThreshold
        ) {
            return false;
        }

        return true;
    }

    function getSqrtRatioX96AtInterval(
        IUniswapV3Pool pool,
        uint32 _twapInterval
    ) public view returns (uint160 sqrtPriceX96) {
        if (_twapInterval == 0) {
            (sqrtPriceX96, , , , , , ) = pool.slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = _twapInterval; // from ago
            secondsAgos[1] = 0; // to now

            (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);

            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(_twapInterval)))
            );
        }
    }

    /*
     ** Helpers
     */
    function floor(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 baseFloor = tick / tickSpacing;

        if (tick < 0 && tick % tickSpacing != 0) {
            return (baseFloor - 1) * tickSpacing;
        }
        return baseFloor * tickSpacing;
    }

    function abs(int24 x) internal pure returns (int24) {
        return x >= 0 ? x : -x;
    }

    function getSqrtRatioX96AndTick(
        IUniswapV3Pool pool
    ) internal view returns (uint160 _sqrtRatioX96, int24 _tick) {
        (_sqrtRatioX96, _tick, , , , , ) = pool.slot0();
    }

    function getBaseTicks(
        int24 currentTick,
        int24 baseTicks,
        int24 tickSpacing
    ) internal pure returns (TicksData memory) {
        int24 tickFloor = floor(currentTick, tickSpacing);

        return TicksData({ tickLower: tickFloor - baseTicks, tickUpper: tickFloor + baseTicks });
    }

    function positionCollectables(
        IUniswapV3Pool pool,
        TicksData memory ticks
    ) internal view returns (uint256, uint256, uint256, uint256) {
        (uint128 liquidity, uint128 fees0, uint128 fees1) = getLiquidityInPosition(pool, ticks);
        (uint256 amount0, uint256 amount1) = getAmountsForLiquidity(pool, liquidity, ticks);

        return (amount0, amount1, fees0, fees1);
    }

    function getReserves(
        IUniswapV3Pool pool,
        TicksData memory ticks
    )
        internal
        returns (uint256 amount0, uint256 amount1, uint256 fees0, uint256 fees1, uint128 liquidity)
    {
        liquidity = pokePosition(pool, ticks);

        if (liquidity > 0) {
            (amount0, amount1, fees0, fees1) = positionCollectables(pool, ticks);
        }
    }

    function getPositionTicks(
        IUniswapV3Pool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        int24 baseTicks,
        int24 tickSpacing
    ) internal view returns (TicksData memory) {
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();

        TicksData memory ticks = getBaseTicks(currentTick, baseTicks, tickSpacing);

        (uint256 amount0, uint256 amount1) = getAmountsForPosition(
            pool,
            amount0Max,
            amount1Max,
            ticks
        );
        uint128 liquidity = getLiquidityForAmounts(pool, amount0, amount1, ticks);
        bool zeroGreaterOne = swapDirection(amount0Max, amount1Max, amount0, amount1);

        if (zeroGreaterOne) {
            uint160 nextSqrt0 = SqrtPriceMath.getNextSqrtPriceFromAmount0RoundingUp(
                sqrtPriceX96,
                liquidity,
                amount0Max,
                false
            );
            ticks.tickUpper = floor(TickMath.getTickAtSqrtRatio(nextSqrt0), tickSpacing);
        } else {
            uint160 nextSqrt1 = SqrtPriceMath.getNextSqrtPriceFromAmount1RoundingDown(
                sqrtPriceX96,
                liquidity,
                amount1Max,
                false
            );
            ticks.tickLower = floor(TickMath.getTickAtSqrtRatio(nextSqrt1), tickSpacing);
        }

        ticks.tickLower = floor(ticks.tickLower, tickSpacing);
        ticks.tickUpper = floor(ticks.tickUpper, tickSpacing);

        if (!isTicksValid(ticks.tickLower, ticks.tickUpper, tickSpacing)) {
            revert Errors.TicksOutOfRange(ticks.tickLower, ticks.tickUpper);
        }

        return ticks;
    }

    function getAmountsForPosition(
        IUniswapV3Pool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        TicksData memory ticks
    ) internal view returns (uint256 amount0, uint256 amount1) {
        uint128 liquidity = getLiquidityForAmounts(pool, amount0Max, amount1Max, ticks);

        (amount0, amount1) = getAmountsForLiquidity(pool, liquidity, ticks);
    }

    function isTicksValid(
        int24 tickLower,
        int24 tickUpper,
        int24 tickSpacing
    ) internal pure returns (bool) {
        return
            tickLower < tickUpper &&
            tickLower >= TickMath.MIN_TICK &&
            tickUpper <= TickMath.MAX_TICK &&
            tickLower % tickSpacing == 0 &&
            tickUpper % tickSpacing == 0;
    }

    function swapDirection(
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (bool zeroGreaterOne) {
        return (amount0Max - amount0) * (amount1Max) > (amount1Max - amount1) * (amount0Max);
    }
}