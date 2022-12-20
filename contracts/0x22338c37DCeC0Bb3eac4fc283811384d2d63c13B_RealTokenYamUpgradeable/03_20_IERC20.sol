// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  // no return value on transfer and transferFrom to tolerate old erc20 tokens
  // we work around that in the buy function by checking balance twice
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external;

  function transfer(address to, uint256 amount) external;

  function decimals() external view returns (uint256);

  function symbol() external view returns (string calldata);

  function name() external view returns (string calldata);
}