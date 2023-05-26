// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
import "./UniswapPoolActions.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "../interfaces/IUnipilotVault.sol";

/// @title Liquidity and ticks functions
/// @notice Provides functions for computing liquidity and ticks for token amounts and prices
library UniswapLiquidityManagement {
    using LowGasSafeMath for uint256;

    struct Info {
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0;
        uint256 amount1;
        uint128 liquidity;
        int24 tickLower;
        int24 tickUpper;
    }

    /// @dev Wrapper around `LiquidityAmounts.getAmountsForLiquidity()`.
    /// @param pool Uniswap V3 pool
    /// @param liquidity  The liquidity being valued
    /// @param _tickLower The lower tick of the range
    /// @param _tickUpper The upper tick of the range
    /// @return amounts of token0 and token1 that corresponds to liquidity
    function getAmountsForLiquidity(
        IUniswapV3Pool pool,
        uint128 liquidity,
        int24 _tickLower,
        int24 _tickUpper
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(_tickLower),
                TickMath.getSqrtRatioAtTick(_tickUpper),
                liquidity
            );
    }

    /// @dev Wrapper around `LiquidityAmounts.getLiquidityForAmounts()`.
    /// @param pool Uniswap V3 pool
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    /// @param _tickLower The lower tick of the range
    /// @param _tickUpper The upper tick of the range
    /// @return The maximum amount of liquidity that can be held amount0 and amount1
    function getLiquidityForAmounts(
        IUniswapV3Pool pool,
        uint256 amount0,
        uint256 amount1,
        int24 _tickLower,
        int24 _tickUpper
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(_tickLower),
                TickMath.getSqrtRatioAtTick(_tickUpper),
                amount0,
                amount1
            );
    }

    /// @dev Amount of liquidity in contract position.
    /// @param pool Uniswap V3 pool
    /// @param _tickLower The lower tick of the range
    /// @param _tickUpper The upper tick of the range
    /// @return liquidity stored in position
    function getPositionLiquidity(
        IUniswapV3Pool pool,
        int24 _tickLower,
        int24 _tickUpper
    )
        internal
        view
        returns (
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        bytes32 positionKey = PositionKey.compute(
            address(this),
            _tickLower,
            _tickUpper
        );
        (liquidity, , , tokensOwed0, tokensOwed1) = pool.positions(positionKey);
    }

    /// @dev Rounds tick down towards negative infinity so that it's a multiple
    /// of `tickSpacing`.
    function floor(int24 tick, int24 tickSpacing)
        internal
        pure
        returns (int24)
    {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

    function getSqrtRatioX96AndTick(IUniswapV3Pool pool)
        internal
        view
        returns (
            uint160 _sqrtRatioX96,
            int24 _tick,
            uint16 observationCardinality
        )
    {
        (_sqrtRatioX96, _tick, , observationCardinality, , , ) = pool.slot0();
    }

    /// @dev Calc base ticks depending on base threshold and tickspacing
    function getBaseTicks(
        int24 currentTick,
        int24 baseThreshold,
        int24 tickSpacing
    ) internal pure returns (int24 tickLower, int24 tickUpper) {
        int24 tickFloor = floor(currentTick, tickSpacing);
        tickLower = tickFloor - baseThreshold;
        tickUpper = tickFloor + baseThreshold;
    }

    function collectableAmountsInPosition(
        IUniswapV3Pool pool,
        int24 _lowerTick,
        int24 _upperTick
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint128 liquidity,
            uint128 earnable0,
            uint128 earnable1
        ) = getPositionLiquidity(pool, _lowerTick, _upperTick);
        (uint256 burnable0, uint256 burnable1) = UniswapLiquidityManagement
            .getAmountsForLiquidity(pool, liquidity, _lowerTick, _upperTick);

        return (burnable0, burnable1, earnable0, earnable1);
    }

    function computeLpShares(
        IUniswapV3Pool pool,
        bool isWhitelisted,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 balance0,
        uint256 balance1,
        uint256 totalSupply,
        IUnipilotVault.TicksData memory ticks
    )
        internal
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        (
            uint256 res0,
            uint256 res1,
            uint256 fees0,
            uint256 fees1,
            ,

        ) = getTotalAmounts(pool, isWhitelisted, ticks);

        uint256 reserve0 = res0.add(fees0).add(balance0);
        uint256 reserve1 = res1.add(fees1).add(balance1);

        // If total supply > 0, pool can't be empty
        assert(totalSupply == 0 || reserve0 != 0 || reserve1 != 0);
        (shares, amount0, amount1) = calculateShare(
            amount0Max,
            amount1Max,
            reserve0,
            reserve1,
            totalSupply
        );
    }

    function getTotalAmounts(
        IUniswapV3Pool pool,
        bool isWhitelisted,
        IUnipilotVault.TicksData memory ticks
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fees0,
            uint256 fees1,
            uint128 baseLiquidity,
            uint128 rangeLiquidity
        )
    {
        (amount0, amount1, fees0, fees1, baseLiquidity) = getReserves(
            pool,
            ticks.baseTickLower,
            ticks.baseTickUpper
        );

        if (!isWhitelisted) {
            (
                uint256 range0,
                uint256 range1,
                uint256 rangeFees0,
                uint256 rangeFees1,
                uint128 rangeliquidity
            ) = getReserves(pool, ticks.rangeTickLower, ticks.rangeTickUpper);

            amount0 = amount0.add(range0);
            amount1 = amount1.add(range1);
            fees0 = fees0.add(rangeFees0);
            fees1 = fees1.add(rangeFees1);
            rangeLiquidity = rangeliquidity;
        }
    }

    function getReserves(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fees0,
            uint256 fees1,
            uint128 liquidity
        )
    {
        liquidity = UniswapPoolActions.updatePosition(
            pool,
            tickLower,
            tickUpper
        );
        if (liquidity > 0) {
            (amount0, amount1, fees0, fees1) = collectableAmountsInPosition(
                pool,
                tickLower,
                tickUpper
            );
        }
    }

    function calculateShare(
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalSupply
    )
        internal
        pure
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        if (totalSupply == 0) {
            // For first deposit, just use the amounts desired
            amount0 = amount0Max;
            amount1 = amount1Max;
            shares = amount0 > amount1 ? amount0 : amount1; // max
        } else if (reserve0 == 0) {
            amount1 = amount1Max;
            shares = FullMath.mulDiv(amount1, totalSupply, reserve1);
        } else if (reserve1 == 0) {
            amount0 = amount0Max;
            shares = FullMath.mulDiv(amount0, totalSupply, reserve0);
        } else {
            amount0 = FullMath.mulDiv(amount1Max, reserve0, reserve1);
            if (amount0 < amount0Max) {
                amount1 = amount1Max;
                shares = FullMath.mulDiv(amount1, totalSupply, reserve1);
            } else {
                amount0 = amount0Max;
                amount1 = FullMath.mulDiv(amount0, reserve1, reserve0);
                shares = FullMath.mulDiv(amount0, totalSupply, reserve0);
            }
        }
    }

    /// @dev Gets ticks with proportion equivalent to desired amount
    /// @param pool Uniswap V3 pool
    /// @param amount0Desired The desired amount of token0
    /// @param amount1Desired The desired amount of token1
    /// @param baseThreshold The range for upper and lower ticks
    /// @param tickSpacing The pool tick spacing
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function getPositionTicks(
        IUniswapV3Pool pool,
        uint256 amount0Desired,
        uint256 amount1Desired,
        int24 baseThreshold,
        int24 tickSpacing
    ) internal view returns (int24 tickLower, int24 tickUpper) {
        Info memory cache = Info(amount0Desired, amount1Desired, 0, 0, 0, 0, 0);
        // Get current price and tick from the pool
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();
        //Calc base ticks
        (cache.tickLower, cache.tickUpper) = getBaseTicks(
            currentTick,
            baseThreshold,
            tickSpacing
        );
        //Calc amounts of token0 and token1 that can be stored in base range
        (cache.amount0, cache.amount1) = getAmountsForTicks(
            pool,
            cache.amount0Desired,
            cache.amount1Desired,
            cache.tickLower,
            cache.tickUpper
        );
        // //Liquidity that can be stored in base range
        cache.liquidity = getLiquidityForAmounts(
            pool,
            cache.amount0,
            cache.amount1,
            cache.tickLower,
            cache.tickUpper
        );

        // //Get imbalanced token
        bool zeroGreaterOne = amountsDirection(
            cache.amount0Desired,
            cache.amount1Desired,
            cache.amount0,
            cache.amount1
        );

        //Calc new tick(upper or lower) for imbalanced token
        if (zeroGreaterOne) {
            uint160 nextSqrtPrice0 = SqrtPriceMath
                .getNextSqrtPriceFromAmount0RoundingUp(
                    sqrtPriceX96,
                    cache.liquidity,
                    cache.amount0Desired,
                    false
                );
            cache.tickUpper = floor(
                TickMath.getTickAtSqrtRatio(nextSqrtPrice0),
                tickSpacing
            );
        } else {
            uint160 nextSqrtPrice1 = SqrtPriceMath
                .getNextSqrtPriceFromAmount1RoundingDown(
                    sqrtPriceX96,
                    cache.liquidity,
                    cache.amount1Desired,
                    false
                );
            cache.tickLower = floor(
                TickMath.getTickAtSqrtRatio(nextSqrtPrice1),
                tickSpacing
            );
        }

        checkRange(cache.tickLower, cache.tickUpper);

        /// floor the tick again because one tick is still not valid tick due to + - baseThreshold
        tickLower = floor(cache.tickLower, tickSpacing);
        tickUpper = floor(cache.tickUpper, tickSpacing);
    }

    /// @dev Gets amounts of token0 and token1 that can be stored in range of upper and lower ticks
    /// @param pool Uniswap V3 pool
    /// @param amount0Desired The desired amount of token0
    /// @param amount1Desired The desired amount of token1
    /// @param _tickLower The lower tick of the range
    /// @param _tickUpper The upper tick of the range
    /// @return amount0 amounts of token0 that can be stored in range
    /// @return amount1 amounts of token1 that can be stored in range
    function getAmountsForTicks(
        IUniswapV3Pool pool,
        uint256 amount0Desired,
        uint256 amount1Desired,
        int24 _tickLower,
        int24 _tickUpper
    ) internal view returns (uint256 amount0, uint256 amount1) {
        uint128 liquidity = getLiquidityForAmounts(
            pool,
            amount0Desired,
            amount1Desired,
            _tickLower,
            _tickUpper
        );

        (amount0, amount1) = getAmountsForLiquidity(
            pool,
            liquidity,
            _tickLower,
            _tickUpper
        );
    }

    /// @dev Common checks for valid tick inputs.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    function checkRange(int24 tickLower, int24 tickUpper) internal pure {
        require(tickLower < tickUpper, "TLU");
        require(tickLower >= TickMath.MIN_TICK, "TLM");
        require(tickUpper <= TickMath.MAX_TICK, "TUM");
    }

    /// @dev Get imbalanced token
    /// @param amount0Desired The desired amount of token0
    /// @param amount1Desired The desired amount of token1
    /// @param amount0 Amounts of token0 that can be stored in base range
    /// @param amount1 Amounts of token1 that can be stored in base range
    /// @return zeroGreaterOne true if token0 is imbalanced. False if token1 is imbalanced
    function amountsDirection(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (bool zeroGreaterOne) {
        zeroGreaterOne = amount0Desired.sub(amount0).mul(amount1Desired) >
            amount1Desired.sub(amount1).mul(amount0Desired)
            ? true
            : false;
    }
}