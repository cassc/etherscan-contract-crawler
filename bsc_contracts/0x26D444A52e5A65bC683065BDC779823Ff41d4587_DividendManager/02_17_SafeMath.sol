// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


library SafeMath {

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0, "SafeMath: Could not convert int256 value to uint256");
    return uint256(a);
  }

  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0, "SafeMath: Could not convert uint256 value to int256");
    return b;
  }
}