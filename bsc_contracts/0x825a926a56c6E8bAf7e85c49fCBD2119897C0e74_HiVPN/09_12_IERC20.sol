// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}