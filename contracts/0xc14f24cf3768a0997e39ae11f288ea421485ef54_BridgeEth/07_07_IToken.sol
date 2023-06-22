// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
  function transfer(address recipient, uint256 amount) external;

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}