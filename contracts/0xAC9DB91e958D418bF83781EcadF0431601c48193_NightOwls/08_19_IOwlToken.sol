// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwlToken {
  function redeemTokens(address addr, uint256 amount) external;
  function onNightOwlTransfer(address from, address to) external;
}