// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev Interface for Converter
 */
interface IConverter {
    struct Period {
        uint128 startTime;
        uint128 endTime;
        uint128 astoMultiplier;
        uint128 lpMultiplier;
        uint128 lbaLPMultiplier;
    }
}