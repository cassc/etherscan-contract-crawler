// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFeeCalc {
  function processDeposit(uint256 amt, address who) external view returns (uint256, uint256);

  function processWithdraw(uint256 amt, address who) external view returns (uint256, uint256);

}