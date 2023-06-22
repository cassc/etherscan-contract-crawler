// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITIMEDividend {
  function claimDividend(
    address payable recipient,
    uint256 amount
  ) external returns (uint256);
  function distributeAll(
    address internetMoneySwapRouter,
    uint256 amount
  ) external;
}