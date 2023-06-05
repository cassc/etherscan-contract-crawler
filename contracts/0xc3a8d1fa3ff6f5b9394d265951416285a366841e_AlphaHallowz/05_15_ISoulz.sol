// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISoulz {
  function soulzBalanceOf(address owner) external view returns (uint256);

  function spendSoulz(address account, uint256 amount) external;
}