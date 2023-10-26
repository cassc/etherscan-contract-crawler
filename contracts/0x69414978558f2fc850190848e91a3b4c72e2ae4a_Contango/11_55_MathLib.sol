//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library MathLib {

    function absIfPositive(int256 value) internal pure returns (uint256) {
        return value > 0 ? uint256(value) : 0;
    }

    function absIfNegative(int256 value) internal pure returns (uint256) {
        unchecked {
            return value < 0 ? uint256(-value) : 0;
        }
    }

}