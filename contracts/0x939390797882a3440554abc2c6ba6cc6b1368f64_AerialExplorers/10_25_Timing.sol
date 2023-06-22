// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

library Timing {
    function isBefore(uint256 a, uint256 b) internal pure returns (bool) {
        return a < b;
    }

    function isAfter(uint256 a, uint256 b) internal pure returns (bool) {
        return a >= b;
    }
}