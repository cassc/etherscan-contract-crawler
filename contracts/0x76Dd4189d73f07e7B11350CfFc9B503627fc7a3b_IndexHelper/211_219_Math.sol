// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.7;

/// @title Math library
/// @notice A library for performing various math operations
library Math {
    /// @notice Returns minimum number among two provided arguments
    /// @param x First argument to compare with the second one
    /// @param y Second argument to compare with the first one
    /// @return z Minimum value among `x` and `y`
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    /// @notice Calculates square root for the given argument
    /// @param y A number to calculate square root for
    /// @dev Uses Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    /// @return z Number `z` whose square is `y`
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}