// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract RandomSequence {
    uint256 internal constant BITS = 15;
    uint256 private constant MASK = (1 << BITS) - 1;
    uint256 private constant B = 8891;
    uint256 private constant A = 32769;

    function _nextRandom(uint256 current) internal pure returns (uint256) {
        return (A * current + B) & MASK;
    }
}