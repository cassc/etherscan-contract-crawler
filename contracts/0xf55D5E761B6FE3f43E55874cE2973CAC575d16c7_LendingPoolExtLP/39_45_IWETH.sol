// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IWETH {
  function balanceOf(address wallet) external view returns (uint256);

  function decimals() external view returns (uint8);

  function deposit() external payable;

  function withdraw(uint256 _amount) external;
}