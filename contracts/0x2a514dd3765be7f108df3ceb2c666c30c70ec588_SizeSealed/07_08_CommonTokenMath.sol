// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

library CommonTokenMath {
    /*//////////////////////////////////////////////////////////////
                                VESTING
    //////////////////////////////////////////////////////////////*/

    //                endTimestamp      vestingStart            vestingEnd
    //        ┌─────────────┬─────────────────┬──────────────────────────────┐
    //        │                                                     │        │
    //        │             │                 │                              │
    //        │                                                     │        │
    //        │             │                 │                     ▽        │
    //        │                                                   ┌── ◁─ ─ ─ ┤totalBaseAmount
    //        │             │                 │                 ┌─┘          │
    //        │                                               ┌─┘            │
    //        │             │                 │             ┌─┘              │
    //        │                                           ┌─┘                │
    //                      │                 │         ┌─┘                  │
    //    Unlocked                                    ┌─┘                    │
    //     Tokens           │                 │     ┌─┘                      │
    //                                            ┌─┘                        │
    //        │             │                 ▽ ┌─┘                          │
    //        │                               ┌─┘◁─ ─ ─ ─ ─ ┐                │
    //        │             │                 │             │                │
    //        │                               │             │                │
    //        │             │                 │        cliffPercent          │
    //        │                               │             │                │
    //        │             │                 │             │                │
    //        │             ▽                 │             │                │
    //        │             ──────────────────┘  ◁─ ─ ─ ─ ─ ┘                │
    //        │                                                              │
    //        └────────────────────────────  Time  ──────────────────────────┘
    //

    /// @dev Helper function to determine tokens at a specific `block.timestamp`
    /// @return tokensAvailable Amount of unlocked `baseToken` at the current `block.timestamp`
    /// @param vestingStart Start of linear vesting
    /// @param vestingEnd Completion of linear vesting
    /// @param currentTime Timestamp to evaluate at
    /// @param cliffPercent Normalized percent to unlock at vesting start
    /// @param baseAmount Total amount of vested `baseToken`
    function tokensAvailableAtTime(
        uint32 vestingStart,
        uint32 vestingEnd,
        uint32 currentTime,
        uint128 cliffPercent,
        uint128 baseAmount
    ) internal pure returns (uint128) {
        if (currentTime > vestingEnd) {
            return baseAmount; // If vesting is over, bidder is owed all tokens
        } else if (currentTime <= vestingStart) {
            return 0; // If cliff hasn't been triggered yet, bidder receives no tokens
        } else {
            // Vesting is active and cliff has triggered
            uint256 cliffAmount = FixedPointMathLib.mulDivDown(baseAmount, cliffPercent, 1e18);

            return uint128(
                cliffAmount
                    + FixedPointMathLib.mulDivDown(
                        baseAmount - cliffAmount, currentTime - vestingStart, vestingEnd - vestingStart
                    )
            );
        }
    }
}