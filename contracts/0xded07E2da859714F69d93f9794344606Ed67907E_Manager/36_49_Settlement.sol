// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./math/TickMath.sol";
import "./Tiers.sol";
import "./Ticks.sol";
import "./TickMaps.sol";
import "./Positions.sol";

library Settlement {
    using TickMaps for TickMaps.TickMap;

    /**
     * @notice                  Data for settling single-sided positions (i.e. filled limit orders)
     * @param liquidityD8       Amount of liquidity to remove
     * @param tickSpacing       Tick spacing of the limit orders
     * @param nextSnapshotId    Next data snapshot id
     * @param snapshots         Array of data snapshots
     */
    struct Info {
        uint96 liquidityD8;
        uint16 tickSpacing;
        uint32 nextSnapshotId;
        mapping(uint32 => Snapshot) snapshots;
    }

    /// @notice Data snapshot when settling the positions
    struct Snapshot {
        uint80 feeGrowthInside0;
        uint80 feeGrowthInside1;
    }

    /**
     * @notice Update the amount of liquidity pending to be settled on a tick, given the lower and upper tick
     * boundaries of a limit-order position.
     * @param settlements       Mapping of settlements of each tick
     * @param ticks             Mapping of ticks of the tier which the position is in
     * @param tickLower         Lower tick boundary of the position
     * @param tickUpper         Upper tick boundary of the position
     * @param limitOrderType    Direction of the limit order (i.e. token0 or token1)
     * @param liquidityDeltaD8  Change of the amount of liquidity to be settled
     * @param isAdd             True if the liquidity change is additive. False otherwise.
     * @param defaultTickSpacing Default tick spacing of limit orders. Only needed when initializing
     * @return nextSnapshotId   Settlement's next snapshot id
     * @return tickSpacing      Tick spacing of the limit orders pending to be settled
     */
    function update(
        mapping(int24 => Info[2]) storage settlements,
        mapping(int24 => Ticks.Tick) storage ticks,
        int24 tickLower,
        int24 tickUpper,
        uint8 limitOrderType,
        uint96 liquidityDeltaD8,
        bool isAdd,
        uint16 defaultTickSpacing
    ) internal returns (uint32 nextSnapshotId, uint16 tickSpacing) {
        assert(limitOrderType == Positions.ZERO_FOR_ONE || limitOrderType == Positions.ONE_FOR_ZERO);

        Info storage settlement = limitOrderType == Positions.ZERO_FOR_ONE
            ? settlements[tickUpper][1]
            : settlements[tickLower][0];

        // update the amount of liquidity to settle
        settlement.liquidityD8 = isAdd
            ? settlement.liquidityD8 + liquidityDeltaD8
            : settlement.liquidityD8 - liquidityDeltaD8;

        // initialize settlement if it's the first limit order at this tick
        nextSnapshotId = settlement.nextSnapshotId;
        if (settlement.tickSpacing == 0) {
            settlement.tickSpacing = defaultTickSpacing;
            settlement.snapshots[nextSnapshotId] = Snapshot(0, 1); // pre-fill to reduce SSTORE gas during swap
        }

        // if no liqudity to settle, clear tick spacing so as to set a latest one next time
        bool isEmpty = settlement.liquidityD8 == 0;
        if (isEmpty) settlement.tickSpacing = 0;

        // update "needSettle" flag in tick state
        if (limitOrderType == Positions.ZERO_FOR_ONE) {
            ticks[tickUpper].needSettle1 = !isEmpty;
        } else {
            ticks[tickLower].needSettle0 = !isEmpty;
        }

        // return data for validating position's settling status
        tickSpacing = settlement.tickSpacing;
    }

    /// @dev Bridging function to sidestep "stack too deep" problem
    function update(
        mapping(int24 => Info[2]) storage settlements,
        mapping(int24 => Ticks.Tick) storage ticks,
        int24 tickLower,
        int24 tickUpper,
        uint8 limitOrderType,
        int96 liquidityDeltaD8,
        uint16 defaultTickSpacing
    ) internal returns (uint32 nextSnapshotId) {
        bool isAdd = liquidityDeltaD8 > 0;
        unchecked {
            (nextSnapshotId, ) = update(
                settlements,
                ticks,
                tickLower,
                tickUpper,
                limitOrderType,
                uint96(isAdd ? liquidityDeltaD8 : -liquidityDeltaD8),
                isAdd,
                defaultTickSpacing
            );
        }
    }

    /**
     * @notice Settle single-sided positions, i.e. filled limit orders, that ends at the tick `tickEnd`.
     * @dev Called during a swap right after tickEnd is crossed. It updates settlement and tick, and possibly tickmap.
     * @param settlements   Mapping of settlements of each tick
     * @param ticks         Mapping of ticks of a tier
     * @param tickMap       Tick bitmap of a tier
     * @param tier          Latest tier data (in memory) currently used in the swap
     * @param tickEnd       Ending tick of the limit orders, i.e. the tick just being crossed in the swap
     * @param token0In      The direction of the ongoing swap
     * @return tickStart    Starting tick of the limit orders, i.e. the other tick besides "tickEnd" that forms the positions
     * @return liquidityD8  Amount of liquidity settled
     */
    function settle(
        mapping(int24 => Info[2]) storage settlements,
        mapping(int24 => Ticks.Tick) storage ticks,
        TickMaps.TickMap storage tickMap,
        Tiers.Tier memory tier,
        int24 tickEnd,
        bool token0In
    ) internal returns (int24 tickStart, uint96 liquidityD8) {
        Info storage settlement; // we assume settlement is intialized
        Ticks.Tick storage start;
        Ticks.Tick storage end = ticks[tickEnd];

        unchecked {
            if (token0In) {
                settlement = settlements[tickEnd][0];
                tickStart = tickEnd + int16(settlement.tickSpacing);
                start = ticks[tickStart];

                // remove liquidity changes on ticks (effect)
                liquidityD8 = settlement.liquidityD8;
                start.liquidityUpperD8 -= liquidityD8;
                end.liquidityLowerD8 -= liquidityD8;
                end.needSettle0 = false;
            } else {
                settlement = settlements[tickEnd][1];
                tickStart = tickEnd - int16(settlement.tickSpacing);
                start = ticks[tickStart];

                // remove liquidity changes on ticks (effect)
                liquidityD8 = settlement.liquidityD8;
                start.liquidityLowerD8 -= liquidityD8;
                end.liquidityUpperD8 -= liquidityD8;
                end.needSettle1 = false;
            }

            // play extra safe to ensure settlement is initialized
            assert(tickStart != tickEnd);

            // snapshot data inside the tick range (effect)
            settlement.snapshots[settlement.nextSnapshotId] = Snapshot(
                end.feeGrowthOutside0 - start.feeGrowthOutside0,
                end.feeGrowthOutside1 - start.feeGrowthOutside1
            );
        }

        // reset settlement state since it's finished (effect)
        settlement.nextSnapshotId++;
        settlement.tickSpacing = 0;
        settlement.liquidityD8 = 0;

        // delete the starting tick if empty (effect)
        if (start.liquidityLowerD8 == 0 && start.liquidityUpperD8 == 0) {
            assert(tickStart != TickMath.MIN_TICK && tickStart != TickMath.MAX_TICK);
            int24 below = start.nextBelow;
            int24 above = start.nextAbove;
            ticks[below].nextAbove = above;
            ticks[above].nextBelow = below;
            delete ticks[tickStart];
            tickMap.unset(tickStart);
        }

        // delete the ending tick if empty (effect), and update tier's next ticks (locally)
        if (end.liquidityLowerD8 == 0 && end.liquidityUpperD8 == 0) {
            assert(tickEnd != TickMath.MIN_TICK && tickEnd != TickMath.MAX_TICK);
            int24 below = end.nextBelow;
            int24 above = end.nextAbove;
            ticks[below].nextAbove = above;
            ticks[above].nextBelow = below;
            delete ticks[tickEnd];
            tickMap.unset(tickEnd);

            // since the tier just crossed tickEnd, we can safely set tier's next ticks in this way
            tier.nextTickBelow = below;
            tier.nextTickAbove = above;
        }
    }

    /**
     * @notice Get data snapshot if the position is a settled limit order
     * @param settlements   Mapping of settlements of each tick
     * @param position      Position state
     * @param tickLower     Position's lower tick boundary
     * @param tickUpper     Position's upper tick boundary
     * @return settled      True if position is settled
     * @return snapshot     Data snapshot if position is settled
     */
    function getSnapshot(
        mapping(int24 => Info[2]) storage settlements,
        Positions.Position storage position,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (bool settled, Snapshot memory snapshot) {
        if (position.limitOrderType == Positions.ZERO_FOR_ONE || position.limitOrderType == Positions.ONE_FOR_ZERO) {
            Info storage settlement = position.limitOrderType == Positions.ZERO_FOR_ONE
                ? settlements[tickUpper][1]
                : settlements[tickLower][0];

            if (position.settlementSnapshotId < settlement.nextSnapshotId) {
                settled = true;
                snapshot = settlement.snapshots[position.settlementSnapshotId];
            }
        }
    }
}