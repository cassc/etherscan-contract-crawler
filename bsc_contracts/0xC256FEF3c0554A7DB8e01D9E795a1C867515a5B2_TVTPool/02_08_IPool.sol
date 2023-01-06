// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
  function userDepositNumber(address user) external view returns (uint256);

  function userDepositDetails(
    address user,
    uint256 index
  ) external view returns (uint256 amount, uint256 startTime);

  function users(
    address user
  )
    external
    view
    returns (address referrer, uint8 percent, uint256 totalTree, uint256 latestWithdraw);
}