// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Tiers {
    struct Tier {
        uint128 liquidity;
        uint128 sqrtPrice; // UQ56.72
        uint24 sqrtGamma; // 5 decimal places
        int24 tick;
        int24 nextTickBelow; // the next lower tick to cross (note that it can be equal to `tier.tick`)
        int24 nextTickAbove; // the next upper tick to cross
        uint80 feeGrowthGlobal0; // UQ16.64
        uint80 feeGrowthGlobal1; // UQ16.64
    }

    /// @dev Update tier's next tick if the given tick is more adjacent to the current tick
    function updateNextTick(Tier storage self, int24 tickNew) internal {
        if (tickNew <= self.tick) {
            if (tickNew > self.nextTickBelow) self.nextTickBelow = tickNew;
        } else {
            if (tickNew < self.nextTickAbove) self.nextTickAbove = tickNew;
        }
    }
}