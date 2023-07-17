// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IWstEth {
  function wrap(uint256 _stETHAmount) external returns (uint256);
}