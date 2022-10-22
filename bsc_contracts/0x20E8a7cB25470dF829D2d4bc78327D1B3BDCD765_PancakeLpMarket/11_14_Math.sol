// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Math {
    function max(int x, int y) internal pure returns (int z) {
        z = x > y ? x : y;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        return x + y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        return x - y;
    }
}