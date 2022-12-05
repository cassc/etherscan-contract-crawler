// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC20 {
  function transfer(address to, uint amount) external returns (bool);

  function approve(address spender, uint amount) external returns (bool);
}