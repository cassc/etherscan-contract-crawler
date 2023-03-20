// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.9;

import "hardhat/console.sol";

library Int256Math {
    function add(int256 a, int b) internal pure returns (int256) {
        return a + b;
    }

    function sub(int256 a, int b) internal pure returns (int256) {
        return a - b;
    }

    function mul(int256 a, int b) internal pure returns (int256) {
        return a * b;
    }

    function div(int256 a, int b) internal pure returns (int256) {
        return a / b;
    }

    function addUint(int256 a, uint b) internal pure returns (int256) {
        return a + int256(b);
    }

    function subUint(int256 a, uint b) internal pure returns (int256) {
        return a - int256(b);
    }

    function mulUint(int256 a, uint b) internal pure returns (int256) {
        return a * int256(b);
    }

    function divUint(int256 a, uint256 b) internal pure returns (int256) {
        return a / int256(b);
    }

    function abs(int256 a) internal pure returns (uint256) {
        return uint256(a < 0 ? -a : a);
    }

    function debug(int256 a) internal view returns (uint) {
        console.log("int number:, num, < 0?", Int256Math.abs(a), a < 0);
        return 0;
    }

    function debug(string memory label, int256 a) internal view returns (uint) {
        console.log("int number:, num, < 0?", label, Int256Math.abs(a), a < 0);
        return 0;
    }
}