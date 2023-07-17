// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Bisect {
    function _getBisectNode(uint256 index, uint256 totalNodes)
        internal
        pure
        returns (uint256)
    {
        require(index > 0, "zero");
        require(index <= totalNodes, "overflow");

        uint256 n = _log2(index);
        uint256 a = totalNodes / 2**(n + 1);
        uint256 b = (totalNodes / 2**n) * (index - 2**n);

        return a + b;
    }

    function _log2(uint256 x) internal pure returns (uint256 result) {
        if (x < 2) {
            result = 0;
        } else if (x < 4) {
            result = 1;
        } else if (x < 8) {
            result = 2;
        } else if (x < 16) {
            result = 3;
        } else if (x < 32) {
            result = 4;
        } else if (x < 64) {
            result = 5;
        } else if (x < 128) {
            result = 6;
        } else if (x < 256) {
            result = 7;
        } else if (x < 512) {
            result = 8;
        } else if (x < 1024) {
            result = 9;
        } else if (x < 2048) {
            result = 10;
        } else if (x < 4096) {
            result = 11;
        } else if (x < 8192) {
            result = 12;
        } else if (x < 16384) {
            result = 13;
        }
    }
}