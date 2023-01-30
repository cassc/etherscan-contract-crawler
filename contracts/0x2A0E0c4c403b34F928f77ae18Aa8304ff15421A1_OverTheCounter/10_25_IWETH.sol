// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IWETH {
  function decimals() external view returns (uint8);

  function deposit() external payable;

  function withdraw(uint256 wad) external;
}