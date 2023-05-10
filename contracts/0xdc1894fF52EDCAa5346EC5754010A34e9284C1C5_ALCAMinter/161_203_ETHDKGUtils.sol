// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ETHDKGUtils {
    function _getThreshold(uint256 numParticipants_) internal pure returns (uint256 threshold) {
        // In our BFT consensus alg, we require t + 1 > 2*n/3.
        // Where t = threshold, n = numParticipants and k = quotient from the integer division
        // There are 3 possibilities for n:
        //
        //  n == 3*k:
        //      We set
        //                          t = 2*k
        //      This implies
        //                      2*k     == t     <= 2*n/3 == 2*k
        //      and
        //                      2*k + 1 == t + 1  > 2*n/3 == 2*k
        //
        //  n == 3*k + 1:
        //      We set
        //                          t = 2*k
        //      This implies
        //                      2*k     == t     <= 2*n/3 == 2*k + 1/3
        //      and
        //                      2*k + 1 == t + 1  > 2*n/3 == 2*k + 1/3
        //
        //  n == 3*k + 2:
        //      We set
        //                          t = 2*k + 1
        //      This implies
        //                      2*k + 1 == t     <= 2*n/3 == 2*k + 4/3
        //      and
        //                      2*k + 2 == t + 1  > 2*n/3 == 2*k + 4/3
        uint256 quotient = numParticipants_ / 3;
        threshold = 2 * quotient;
        uint256 remainder = numParticipants_ - 3 * quotient;
        if (remainder == 2) {
            threshold = threshold + 1;
        }
    }

    function _isBitSet(uint256 self, uint8 index) internal pure returns (bool) {
        uint256 val;
        assembly ("memory-safe") {
            val := and(shr(index, self), 1)
        }
        return (val == 1);
    }

    function _setBit(uint256 self, uint8 index) internal pure returns (uint256) {
        assembly ("memory-safe") {
            self := or(shl(index, 1), self)
        }
        return (self);
    }
}