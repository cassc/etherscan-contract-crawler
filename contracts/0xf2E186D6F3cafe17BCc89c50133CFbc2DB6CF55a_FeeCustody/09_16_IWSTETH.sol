// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWSTETH {
  function unwrap(uint256 _amount) external returns (uint256);

  function getStETHByWstETH(uint256 _wstETHAmount)
    external
    view
    returns (uint256);
}