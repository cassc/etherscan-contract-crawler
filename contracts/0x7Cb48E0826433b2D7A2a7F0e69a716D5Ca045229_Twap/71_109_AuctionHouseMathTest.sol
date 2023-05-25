// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../AuctionHouseMath.sol";

contract AuctionHouseMathTest is AuctionHouseMath {
  function _lerp(
    uint256 start,
    uint256 end,
    uint16 step,
    uint16 maxStep
  ) public pure returns (uint256 result) {
    return lerp(start, end, step, maxStep);
  }
}