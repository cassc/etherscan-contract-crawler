// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return a;
        return b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        return b;
    }
}