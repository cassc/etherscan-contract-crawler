// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.9;

library Uint256ExtendMath {
    function add(uint256 a, int256 b) internal pure returns (int256) {
        int256 c = int256(a) + b;
        return c;
    }

    function sub(uint256 a, int256 b) internal pure returns (int256) {
        int256 c = int256(a) - b;
        return c;
    }

    function mul(uint256 a, int256 b) internal pure returns (int256) {
        int256 c = int256(a) * b;
        return c;
    }

    function div(uint256 a, int256 b) internal pure returns (int256) {
        int256 c = int256(a) / b;
        return c;
    }
}