// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library Integers {
    function toInt128(uint256 u) internal pure returns (int128) {
        return int128(int256(u));
    }

    function toUint256(int128 i) internal pure returns (uint256) {
        return uint256(uint128(i));
    }
}