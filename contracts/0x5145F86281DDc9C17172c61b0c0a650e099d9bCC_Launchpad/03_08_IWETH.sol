// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IWETH {

  function deposit() external payable;

  function balanceOf(address addr) external view returns (uint256);
}