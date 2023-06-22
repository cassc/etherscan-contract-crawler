// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

import '@pancakeswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@pancakeswap/v3-core/contracts/libraries/SafeCast.sol';

import '@pancakeswap/v3-core/contracts/libraries/TickMath.sol';
import '@pancakeswap/v3-core/contracts/libraries/LiquidityMath.sol';

/// @title LmTick
/// @notice Contains functions for managing tick processes and relevant calculations
library LmTick {
    using LowGasSafeMath for int256;
    using SafeCast for int256;

    // info stored for each initialized individual tick
    struct Info {
        // the total position liquidity that references this tick
        uint128 liquidityGross;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityNet;
        // reward growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint256 rewardGrowthOutsideX128;
    }

    /// @notice Retrieves reward growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @param tickCurrent The current tick
    /// @param rewardGrowthGlobalX128 The all-time global reward growth, per unit of liquidity
    /// @return rewardGrowthInsideX128 The all-time reward growth, per unit of liquidity, inside the position's tick boundaries
    function getRewardGrowthInside(
        mapping(int24 => LmTick.Info) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 rewardGrowthGlobalX128
    ) internal view returns (uint256 rewardGrowthInsideX128) {
        Info storage lower = self[tickLower];
        Info storage upper = self[tickUpper];

        // calculate reward growth below
        uint256 rewardGrowthBelowX128;
        if (tickCurrent >= tickLower) {
            rewardGrowthBelowX128 = lower.rewardGrowthOutsideX128;
        } else {
            rewardGrowthBelowX128 = rewardGrowthGlobalX128 - lower.rewardGrowthOutsideX128;
        }

        // calculate reward growth above
        uint256 rewardGrowthAboveX128;
        if (tickCurrent < tickUpper) {
            rewardGrowthAboveX128 = upper.rewardGrowthOutsideX128;
        } else {
            rewardGrowthAboveX128 = rewardGrowthGlobalX128 - upper.rewardGrowthOutsideX128;
        }

        rewardGrowthInsideX128 = rewardGrowthGlobalX128 - rewardGrowthBelowX128 - rewardGrowthAboveX128;
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param tickCurrent The current tick
    /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
    /// @param rewardGrowthGlobalX128 The all-time global reward growth, per unit of liquidity
    /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
    /// @param maxLiquidity The maximum liquidity allocation for a single tick
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => LmTick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 rewardGrowthGlobalX128,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {
        LmTick.Info storage info = self[tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(liquidityGrossBefore, liquidityDelta);

        require(liquidityGrossAfter <= maxLiquidity, 'LO');

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= tickCurrent) {
                info.rewardGrowthOutsideX128 = rewardGrowthGlobalX128;
            }
        }

        info.liquidityGross = liquidityGrossAfter;

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.liquidityNet = upper
            ? int256(info.liquidityNet).sub(liquidityDelta).toInt128()
            : int256(info.liquidityNet).add(liquidityDelta).toInt128();
    }

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(mapping(int24 => LmTick.Info) storage self, int24 tick) internal {
        delete self[tick];
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The destination tick of the transition
    /// @param rewardGrowthGlobalX128 The all-time global reward growth, per unit of liquidity, in token0
    /// @return liquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross(
        mapping(int24 => LmTick.Info) storage self,
        int24 tick,
        uint256 rewardGrowthGlobalX128
    ) internal returns (int128 liquidityNet) {
        LmTick.Info storage info = self[tick];
        info.rewardGrowthOutsideX128 = rewardGrowthGlobalX128 - info.rewardGrowthOutsideX128;
        liquidityNet = info.liquidityNet;
    }
}