//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Lib Uint256
/// @notice Utilities to perform uint operations
library LibUint256 {
    /// @notice Converts a value to little endian (64 bits)
    /// @param _value The value to convert
    /// @return result The converted value
    function toLittleEndian64(uint256 _value) internal pure returns (uint256 result) {
        result = 0;
        uint256 tempValue = _value;
        result = tempValue & 0xFF;
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        assert(0 == tempValue); // fully converted
        result <<= (24 * 8);
    }

    /// @notice Returns the minimum value
    /// @param _a First value
    /// @param _b Second value
    /// @return Smallest value between _a and _b
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a > _b ? _b : _a);
    }
}