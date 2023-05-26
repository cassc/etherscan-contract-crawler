// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface IERC20 {
  function totalSupply() external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function decimals() external view returns (uint8);

  function balanceOf(address) external view returns (uint);

  function transferFrom(address sender, address recipient, uint amount) external returns (bool);

  function approve(address spender, uint value) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);
}