// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library TypeConvert {

    function toUint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max)); // dev: toInt overflow
        return int256(x);
    }

    function toInt80(int256 x) internal pure returns (int80) {
        require (int256(type(int80).min) <= x && x <= int256(type(int80).max)); // dev: toInt overflow
        return int80(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        require (x <= uint256(type(uint80).max));
        return uint80(x);
    }
}