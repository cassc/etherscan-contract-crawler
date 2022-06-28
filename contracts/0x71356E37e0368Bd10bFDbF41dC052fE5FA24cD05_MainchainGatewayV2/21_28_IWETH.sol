// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 _wad) external;

  function balanceOf(address) external view returns (uint256);
}