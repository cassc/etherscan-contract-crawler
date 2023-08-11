// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../uniswap/interfaces.sol";
import "./LogPowMath.sol";

library UniswapOracle {

    using UniswapOracle for address;

    struct Observation {
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        bool initialized;
    }

    /// @dev query a certain observation from uniswap pool
    /// @param pool address of uniswap pool
    /// @param observationIndex index of wanted observation
    /// @return observation desired observation, see Observation to learn more
    function getObservation(address pool, uint observationIndex)
        internal
        view
        returns (Observation memory observation) 
    {
        (
            observation.blockTimestamp,
            observation.tickCumulative,
            observation.secondsPerLiquidityCumulativeX128,
            observation.initialized
        ) = IUniswapV3Pool(pool).observations(observationIndex);
    }

    /// @dev query latest and oldest observations from uniswap pool
    /// @param pool address of uniswap pool
    /// @param latestIndex index of latest observation in the pool
    /// @param observationCardinality size of observation queue in the pool
    /// @return oldestObservation
    /// @return latestObservation
    function getObservationBoundary(address pool, uint16 latestIndex, uint16 observationCardinality)
        internal
        view
        returns (Observation memory oldestObservation, Observation memory latestObservation)
    {
        uint16 oldestIndex = (latestIndex + 1) % observationCardinality;
        oldestObservation = pool.getObservation(oldestIndex);
        if (!oldestObservation.initialized) {
            oldestIndex = 0;
            oldestObservation = pool.getObservation(0);
        }
        if (latestIndex == oldestIndex) {
            // oldest observation is latest observation
            latestObservation = oldestObservation;
        } else {
            latestObservation = pool.getObservation(latestIndex);
        }
    }

    struct Slot0 {
        int24 tick;
        uint160 sqrtPriceX96;
        uint16 observationIndex;
        uint16 observationCardinality;
    }

    /// @dev view slot0 infomations from uniswap pool
    /// @param pool address of uniswap
    /// @return slot0 a Slot0 struct with necessary info, see Slot0 struct above
    function getSlot0(address pool) 
        internal
        view
        returns (Slot0 memory slot0) {
        (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,
        
        ) = IUniswapV3Pool(pool).slot0();
        slot0.tick = tick;
        slot0.sqrtPriceX96 = sqrtPriceX96;
        slot0.observationIndex = observationIndex;
        slot0.observationCardinality = observationCardinality;
    }

    // note if we call this interface, we must ensure that the 
    //    oldest observation preserved in pool is older than 2h ago
    function _getAvgTickFromTarget(address pool, uint32 targetTimestamp, int56 latestTickCumu, uint32 latestTimestamp)
        private
        view
        returns (int24 tick) 
    {
        uint32[] memory secondsAgo = new uint32[](1);
        secondsAgo[0] = uint32(block.timestamp) - targetTimestamp;

        int56[] memory tickCumulatives;
        
        (tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgo);
        uint56 timeDelta = latestTimestamp - targetTimestamp;

        int56 tickAvg = (latestTickCumu - tickCumulatives[0]) / int56(timeDelta);
        tick = int24(tickAvg);
    }

    /// @dev compute avg tick and avg sqrt price of pool within one hour from now
    /// @param pool address of uniswap pool
    /// @return tick computed avg tick
    /// @return sqrtPriceX96 computed avg sqrt price, in the form of 96-bit fixed point number
    function getAvgTickPriceWithin2Hour(address pool)
        internal
        view
        returns (int24 tick, uint160 sqrtPriceX96, int24 currTick, uint160 currSqrtPriceX96)
    {
        Slot0 memory slot0 = pool.getSlot0();

        if (slot0.observationCardinality == 1) {
            // only 1 observation in the swap pool
            // we could simply return tick/sqrtPrice of slot0
            return (slot0.tick, slot0.sqrtPriceX96, slot0.tick, slot0.sqrtPriceX96);
        } else {
            // we will search the latest observation and the observation 1h ago 

            // 1st, we should get the boundary of the observations in the pool
            Observation memory oldestObservation;
            Observation memory latestObservation;
            (oldestObservation, latestObservation) = pool.getObservationBoundary(slot0.observationIndex, slot0.observationCardinality);
            
            if (oldestObservation.blockTimestamp == latestObservation.blockTimestamp) {
                // there is only 1 valid observation in the pool
                return (slot0.tick, slot0.sqrtPriceX96, slot0.tick, slot0.sqrtPriceX96);
            }
            uint32 twoHourAgo = uint32(block.timestamp - 7200);

            // now there must be at least 2 valid observations in the pool
            if (twoHourAgo <= oldestObservation.blockTimestamp || latestObservation.blockTimestamp <= oldestObservation.blockTimestamp + 3600) {
                // the oldest observation updated within 1h
                // we can not safely call IUniswapV3Pool.observe(...) for it 1h ago
                uint56 timeDelta = latestObservation.blockTimestamp - oldestObservation.blockTimestamp;
                int56 tickAvg = (latestObservation.tickCumulative - oldestObservation.tickCumulative) / int56(timeDelta);
                tick = int24(tickAvg);
            } else {
                // we are sure that the oldest observation is old enough
                // we can safely call IUniswapV3Pool.observe(...) for it 1h ago
                uint32 targetTimestamp = twoHourAgo;
                if (targetTimestamp + 3600 > latestObservation.blockTimestamp) {
                    targetTimestamp = latestObservation.blockTimestamp - 3600;
                }
                tick = _getAvgTickFromTarget(pool, targetTimestamp, latestObservation.tickCumulative, latestObservation.blockTimestamp);
            }
            sqrtPriceX96 = LogPowMath.getSqrtPrice(tick);
            return (tick, sqrtPriceX96, slot0.tick, slot0.sqrtPriceX96);
        }
    }
}