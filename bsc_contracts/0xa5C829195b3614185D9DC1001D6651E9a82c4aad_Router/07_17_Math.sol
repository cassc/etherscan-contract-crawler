// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

// a library for performing various math operations
// Copy from "@uniswap/v2-core/contracts/libraries/Math.sol" and change solidity version

library Math {
    function abs(int x) internal pure returns (uint z) {
        z = uint(x >= 0 ? x : -x);
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        z = x > y ? x : y;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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