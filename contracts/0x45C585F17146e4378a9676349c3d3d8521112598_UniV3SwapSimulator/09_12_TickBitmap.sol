// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "BitMath.sol";

interface IUniswapV3PoolBitmap {
    function tickBitmap(int16 wordPosition) external view returns (uint256);
}

struct TickNextWithWordQuery{
    address pool;
    int24 tick;
    int24 tickSpacing;
    bool lte;
}

// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickBitmap.sol
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(tick % 256);
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param _query.pool The Uniswap V3 pool to fetch the ticks BitMap
    /// @param _query.tick The starting tick
    /// @param _query.tickSpacing The spacing between usable ticks
    /// @param _query.lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(TickNextWithWordQuery memory _query) internal view returns (int24 next, bool initialized) {
        int24 compressed = _query.tick / _query.tickSpacing;
        if (_query.tick < 0 && _query.tick % _query.tickSpacing != 0) compressed--; // round towards negative infinity

        if (_query.lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = IUniswapV3PoolBitmap(_query.pool).tickBitmap(wordPos) & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * _query.tickSpacing
                : (compressed - int24(bitPos)) * _query.tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked =  IUniswapV3PoolBitmap(_query.pool).tickBitmap(wordPos) & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) *_query. tickSpacing
                : (compressed + 1 + int24(type(uint8).max - bitPos)) * _query.tickSpacing;
        }
    }
}