// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

library MathHelper {
  function diff(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x > y ? x - y : y - x;
  }
}