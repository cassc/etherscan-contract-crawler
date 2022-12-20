// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMigration {
  struct Balance {
    uint256 amount;
    uint256 validUntil;
  }
  function balanceOf(address account) external view returns(uint);
  function totalSupply() external view returns(uint);
}