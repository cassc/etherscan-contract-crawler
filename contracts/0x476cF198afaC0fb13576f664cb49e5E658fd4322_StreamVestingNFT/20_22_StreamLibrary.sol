// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library StreamLibrary {
  function min(uint256 a, uint256 b) internal pure returns (uint256 _min) {
    _min = (a <= b) ? a : b;
  }

  function endDate(
    uint256 start,
    uint256 rate,
    uint256 amount
  ) internal pure returns (uint256 end) {
    end = (amount % rate) == 0 ? (amount / rate) + start : (amount / rate) + start + 1;
  }

  function streamBalanceAtTime(
    uint256 start,
    uint256 cliff,
    uint256 amount,
    uint256 rate,
    uint256 time
  ) internal pure returns (uint256 balance, uint256 remainder) {
    if (start >= time || cliff >= time) {
      remainder = amount;
    } else {
      balance = min((time - start) * rate, amount);
      remainder = amount - balance;
    }
  }
}