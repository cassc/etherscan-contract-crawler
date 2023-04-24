// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library MaxMinMath {

    function max(int24 a, int24 b) internal pure returns (int24) {
        if (a > b) {
            return a;
        }
        return b;
    }

    function min(int24 a, int24 b) internal pure returns (int24) {
        if (a < b) {
            return a;
        }
        return b;
    }

    function min(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a < b) {
            return a;
        }
        return b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }
    
}