// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library SignificantBit {
    /**
     * @notice Finds the index of the least significant bit.
     * @param x The value to compute the least significant bit for. Must be a non-zero value.
     * @return ret The index of the least significant bit.
     */
    function leastSignificantBit(uint256 x) internal pure returns (uint8 ret) {
        unchecked {
            require(x > 0);
            ret = 0;
            uint256 mask = type(uint128).max;
            uint8 shifter = 128;
            while (x & 1 == 0) {
                if (x & mask == 0) {
                    ret += shifter;
                    x >>= shifter;
                }
                shifter >>= 1;
                mask >>= shifter;
            }
        }
    }
}