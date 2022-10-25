// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library Numbers {
  function percent(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / 10000;
  }

  function percentOf(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * 10000) / b;
  }

  function discount(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - percent(a, b);
  }

  function markup(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + percent(a, b);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return b > a ? 0 : a - b;
    }
  }
}