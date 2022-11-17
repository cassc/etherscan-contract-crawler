// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;

library Utils {
  function divRoundUp(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0, "SafeMath: division by zero");
    c = a / b;
    if (b * c != a) c += 1;
  }
}