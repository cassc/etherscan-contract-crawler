// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

library PreciseMath {
    uint256 internal constant PRECISE_UNIT = 10**18;

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b / PRECISE_UNIT;
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * PRECISE_UNIT / b;
    }
}