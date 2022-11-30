// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC20.sol";

interface IWETH {
  function allowance(address, address) external returns (uint256);

  function balanceOf(address) external returns (uint256);

  function approve(address, uint256) external;

  function transfer(address, uint256) external returns (bool);

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);

  function deposit() external payable;

  function withdraw(uint256) external;
}