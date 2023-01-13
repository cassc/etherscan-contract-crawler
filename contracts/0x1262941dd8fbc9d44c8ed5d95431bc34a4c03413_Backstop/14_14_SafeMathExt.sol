// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

library SafeMathExt {
  uint256 private constant FP_DECIMALS = 1e18;

  /**
   * @notice Subtract, respecting numerical bounds of the type
   */
  function saturatingSub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a - b : 0;
  }

  /// @notice Multiply two fixed point numbers, base 1e18
  function decMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / FP_DECIMALS;
  }

  function decDiv(uint256 divisor, uint256 dividend) internal pure returns (uint256) {
    uint256 preRound = (divisor * (FP_DECIMALS ** 2) / dividend);
    uint256 subPrecisionComponent = preRound % FP_DECIMALS;
    uint256 correction = subPrecisionComponent >= (FP_DECIMALS / 2) ? 1 : 0;
    return (preRound / FP_DECIMALS) + correction;
  }
}