// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapFactoryEvents {
    /**
     * @notice Emitted when a new Pair is created.
     * @param token0 The first sorted token
     * @param token1 The second sorted token
     * @param pair The address of the new {ButtonswapPair} contract
     * @param count The new total number of Pairs created
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 count);

    /**
     * @notice Emitted when the default parameters for a new pair have been updated.
     * @param paramSetter The address that changed the parameters
     * @param newDefaultMovingAverageWindow The new movingAverageWindow default value
     * @param newDefaultMaxVolatilityBps The new maxVolatilityBps default value
     * @param newDefaultMinTimelockDuration The new minTimelockDuration default value
     * @param newDefaultMaxTimelockDuration The new maxTimelockDuration default value
     * @param newDefaultMaxSwappableReservoirLimitBps The new maxSwappableReservoirLimitBps default value
     * @param newDefaultSwappableReservoirGrowthWindow The new swappableReservoirGrowthWindow default value
     */
    event DefaultParametersUpdated(
        address indexed paramSetter,
        uint32 newDefaultMovingAverageWindow,
        uint16 newDefaultMaxVolatilityBps,
        uint32 newDefaultMinTimelockDuration,
        uint32 newDefaultMaxTimelockDuration,
        uint16 newDefaultMaxSwappableReservoirLimitBps,
        uint32 newDefaultSwappableReservoirGrowthWindow
    );
}