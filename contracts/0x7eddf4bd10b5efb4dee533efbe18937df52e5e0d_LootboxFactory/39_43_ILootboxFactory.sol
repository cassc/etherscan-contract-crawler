// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILootboxFactory {
  function feePerUnit(address _lootbox) external view returns (uint);
  receive() external payable;
}