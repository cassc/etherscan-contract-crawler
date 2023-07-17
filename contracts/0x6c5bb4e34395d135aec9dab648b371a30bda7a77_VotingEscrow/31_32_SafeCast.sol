// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

/// @title SafeCast library
/// @author leNFT
/// @notice Casting utilities
/// @dev This library is used to safely cast between uint256 and smaller sized unsigned integers
library SafeCast {
    /// @notice Cast a uint256 to a uint32, revert on overflow
    /// @param value The uint256 value to be casted
    /// @return The uint32 value casted from uint256
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SC:CAST16_OVERFLOW");
        return uint16(value);
    }

    /// @notice Cast a uint256 to a uint40, revert on overflow
    /// @param value The uint256 value to be casted
    /// @return The uint40 value casted from uint256
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SC:CAST40_OVERFLOW");
        return uint40(value);
    }

    /// @notice Cast a uint256 to a uint64, revert on overflow
    /// @param value The uint256 value to be casted
    /// @return The uint64 value casted from uint256
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SC:CAST64_OVERFLOW");
        return uint64(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SC:CAST128_OVERFLOW");
        return uint128(value);
    }
}