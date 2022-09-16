// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.7;

/// @title UQ library
/// @notice A library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
/// @dev range: [0, 2**112 - 1]
/// @dev resolution: 1 / 2**112
library UQ112x112 {
    /// @notice Constant used to encode / decode a number to / from UQ format
    uint224 constant Q112 = 2**112;

    /// @notice Encodes a uint112 as a UQ112x112
    /// @param y Number to encode
    /// @return z UQ encoded value
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    /// @notice Divides a UQ112x112 by a uint112, returning a UQ112x112
    /// @param x Dividend value
    /// @param y Divisor value
    /// @return z Result of `x` divided by `y`
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}