// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Integers {
    error OutOfRange();

    function toInt128(uint256 u) internal pure returns (int128) {
        revertIfOutOfRange(u <= uint256(uint128(type(int128).max)));
        return int128(int256(u));
    }

    function toUint192(uint256 u) internal pure returns (uint192) {
        revertIfOutOfRange(u <= uint256(type(uint192).max));
        return uint192(u);
    }

    function toUint256(int128 i) internal pure returns (uint256) {
        revertIfOutOfRange(i >= 0);
        return uint256(uint128(i));
    }

    function revertIfOutOfRange(bool success) internal pure {
        if (!success) revert OutOfRange();
    }
}