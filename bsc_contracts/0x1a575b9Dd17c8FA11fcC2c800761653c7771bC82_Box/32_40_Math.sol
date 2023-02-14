// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Math {
    uint16 public constant SHORT_FIXED_DECIMAL_FACTOR = 10**3;
    uint24 public constant MEDIUM_FIXED_DECIMAL_FACTOR = 10**6;
    uint256 public constant LONG_FIXED_DECIMAL_FACTOR = 10**30;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}