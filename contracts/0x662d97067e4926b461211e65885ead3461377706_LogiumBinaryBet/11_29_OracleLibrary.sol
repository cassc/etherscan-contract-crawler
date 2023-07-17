// SPDX-License-Identifier: GPL-2.0-or-later
// Altered implementation from https://github.com/Uniswap/v3-periphery/blob/ee7982942e4397f67e32c291ebed6bcf7210a8f5/contracts/libraries/OracleLibrary.sol
// including elements of https://github.com/Uniswap/v3-core/tree/fc2107bd5709cdee6742d5164c1eb998566bcb75/contracts libraries and interfaces (only licensed "GPL-2.0-or-later")
pragma solidity ^0.8.0;
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title Oracle Library
/// @notice redone implementation consult function of official Uniswap/v3-periphery OracleLibrary for solidity 0.8
library OracleLibrary {
    /// @dev uniswap min tick value
    int24 internal constant MIN_TICK = -887272;
    /// @dev uniswap max tick value
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @notice Calculates current tick for a given Uniswap V3 pool using oracle data/observations buffer to avoid flash-loan possibility
    /// @param pool Address of the pool that we want to observe
    /// @return tick The tick
    function consult(IUniswapV3Pool pool) internal view returns (int24) {
        (
            ,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = pool.slot0();
        (
            uint32 o1blockTimestamp,
            int56 o1tickCumulative,
            ,
            bool o1initialized
        ) = pool.observations(observationIndex);
        require(o1initialized, "Oracle uninitialized"); // sanity check
        // if newest observation.timestamp is not from current block
        // than there were no swaps on this pool in current block and we can use slot0 tick
        if (o1blockTimestamp != uint32(block.timestamp)) return tick;
        else {
            // if there were any swaps in the current block, we use the oracle UniV3 feature
            // this is only possible if there are at least 2 observations available
            require(observationCardinality > 1, "OLD"); // same as uniswap impl. error
            uint16 prevObservation = observationIndex > 0
                ? observationIndex - 1
                : observationCardinality - 1;
            (
                uint32 o2blockTimestamp,
                int56 o2tickCumulative,
                ,
                bool o2initialized
            ) = pool.observations(prevObservation);
            require(o2initialized, "Oracle uninitialized"); // sanity check
            require(
                o2blockTimestamp != 0 && o1blockTimestamp > o2blockTimestamp,
                "Invalid oracle state"
            ); // sanity check
            uint32 delta = o1blockTimestamp - o2blockTimestamp;
            int56 result = (o1tickCumulative - o2tickCumulative) /
                int56(uint56(delta));
            require(result >= MIN_TICK, "TLM"); // sanity check
            require(result <= MAX_TICK, "TUM"); // sanity check
            return int24(result);
        }
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        unchecked {
            uint256 absTick = tick < 0
                ? uint256(-int256(tick))
                : uint256(int256(tick));
            require(absTick <= uint256(int256(MAX_TICK)), "T");

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0)
                ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0)
                ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0)
                ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0)
                ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0)
                ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0)
                ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0)
                ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0)
                ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0)
                ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0)
                ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0)
                ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0)
                ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0)
                ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0)
                ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0)
                ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0)
                ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0)
                ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0)
                ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0)
                ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160(
                (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
            );
        }
    }
}