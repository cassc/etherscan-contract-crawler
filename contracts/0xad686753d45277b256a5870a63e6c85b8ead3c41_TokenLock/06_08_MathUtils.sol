// SPDX-License-Identifier: MIT

// https://github.com/graphprotocol/token-distribution/blob/68f0063c33ece0460bbf8ca3c3699545838c3217/contracts/MathUtils.sol

pragma solidity ^0.7.3;

library MathUtils {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}