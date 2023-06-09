// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library SafeCast {
    error CastError();

    /// @notice This is used to safely case timestamps to uint8
    uint256 private constant MAX_UINT_8 = type(uint8).max;
    /// @notice This is used to safely case timestamps to uint32
    uint256 private constant MAX_UINT_32 = type(uint32).max;
    /// @notice This is used to safely case timestamps to uint80
    uint256 private constant MAX_UINT_80 = type(uint80).max;
    /// @notice This is used to safely case timestamps to uint96
    uint256 private constant MAX_UINT_96 = type(uint96).max;

    function _toUint8(uint256 value) internal pure returns (uint8) {
        if (value > MAX_UINT_8) revert CastError();
        return uint8(value);
    }

    function _toUint32(uint256 value) internal pure returns (uint32) {
        if (value > MAX_UINT_32) revert CastError();
        return uint32(value);
    }

    function _toUint80(uint256 value) internal pure returns (uint80) {
        if (value > MAX_UINT_80) revert CastError();
        return uint80(value);
    }

    function _toUint96(uint256 value) internal pure returns (uint96) {
        if (value > MAX_UINT_96) revert CastError();
        return uint96(value);
    }
}