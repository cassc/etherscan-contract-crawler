// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library SafeMathX {
    // Calculate x * y / scale rounding down.
    function mulScale(uint256 x, uint256 y, uint128 scale) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
}