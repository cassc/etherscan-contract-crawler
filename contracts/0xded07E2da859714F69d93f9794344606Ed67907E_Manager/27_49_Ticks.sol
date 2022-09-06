// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Ticks {
    /**
     * @param liquidityLowerD8  Liquidity from positions with lower tick boundary at this tick
     * @param liquidityUpperD8  Liquidity from positions with upper tick boundary at this tick
     * @param nextBelow         Next initialized tick below this tick
     * @param nextAbove         Next initialized tick above this tick
     * @param needSettle0       True if needed to settle positions with lower tick boundary at this tick (i.e. 1 -> 0 limit orders)
     * @param needSettle1       True if needed to settle positions with upper tick boundary at this tick (i.e. 0 -> 1 limit orders)
     * @param feeGrowthOutside0 Fee0 growth per unit liquidity from this tick to the end in a direction away from the tier's current tick (UQ16.64)
     * @param feeGrowthOutside1 Fee1 growth per unit liquidity from this tick to the end in a direction away from the tier's current tick (UQ16.64)
     */
    struct Tick {
        uint96 liquidityLowerD8;
        uint96 liquidityUpperD8;
        int24 nextBelow;
        int24 nextAbove;
        bool needSettle0;
        bool needSettle1;
        uint80 feeGrowthOutside0;
        uint80 feeGrowthOutside1;
    }

    /// @dev Flip the direction of "outside". Called when the tick is being crossed.
    function flip(
        Tick storage self,
        uint80 feeGrowthGlobal0,
        uint80 feeGrowthGlobal1
    ) internal {
        unchecked {
            self.feeGrowthOutside0 = feeGrowthGlobal0 - self.feeGrowthOutside0;
            self.feeGrowthOutside1 = feeGrowthGlobal1 - self.feeGrowthOutside1;
        }
    }
}