// SPDX-License-Identifier: MIT
// Cannot direct import from @uniswap/v3-core since pragma needs to be changed from <0.8.0 to <0.9.0 for compatibility
pragma solidity >=0.5.0 <0.9.0;

/// @title Oracle
/// @notice Provides price and liquidity data useful for a wide variety of system designs
/// @dev Instances of stored oracle data, "observations", are collected in the oracle array
/// Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the oracle array. New slots will be added when the array is fully populated.
/// Observations are overwritten when the full length of the oracle array is populated.
/// The most recent observation is available, independent of the length of the oracle array, by passing 0 to observe()
library Oracle {
    /// @notice Taken from https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/Oracle.sol
    struct Observation {
        // the block timestamp of the observation
        uint32 blockTimestamp;
        // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
        uint160 secondsPerLiquidityCumulativeX128;
        // whether or not the observation is initialized
        bool initialized;
    }

    /// @dev For testing purposes only
    /// @notice Returns Observation as it is laid out in EVM storage:
    /// concatenation of `initialized . secondsPerLiquidityCumulativeX128 . tickCumulative . blockTimestamp`
    function pack(Observation memory observation) public pure returns (bytes32 packed) {
        packed = bytes32(
            bytes.concat(
                bytes1(observation.initialized ? 0x01 : 0x00),
                bytes20(observation.secondsPerLiquidityCumulativeX128),
                bytes7(uint56(observation.tickCumulative)),
                bytes4(observation.blockTimestamp)
            )
        );
    }
}