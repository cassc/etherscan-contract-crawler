// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
  function balanceOf(address who) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external returns (uint256);
  function transferFrom(address src, address dst, uint wad) external returns (bool);
}