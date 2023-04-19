// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function roundUp(uint256 fraction, uint256 denominator) internal pure returns (uint256) {
        uint256 imprecise = fraction / denominator;
        bool shouldRound = fraction - imprecise * denominator > 0;

        return shouldRound ? imprecise + 1 : imprecise;
    }
}