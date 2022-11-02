// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
  function mint(address to, uint256 amount) external;

  function withdraw(
    address token,
    address to,
    uint256 amount
  ) external;

  function increaseMintLimit(address minter, uint256 amount) external;

  function decreaseMintLimit(address minter, uint256 amount) external;

  function increaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  function decreaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  event Mint(address indexed to, uint256 amount);
  event Withdraw(address indexed token, address indexed to, uint256 amount);
  event MintLimitUpdate(address indexed minter, uint256 amount);
  event WithdrawLimitUpdate(
    address indexed token,
    address indexed minter,
    uint256 amount
  );
}