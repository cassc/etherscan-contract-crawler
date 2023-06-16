// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IBuyAndBurn {
  function deposit(uint256 amount) external;
  function withdraw(address destination, uint256 amount) external;
  function claimDividend(uint256 amount) external returns(uint256);
  function buy(uint256 amountIn, uint256 minAmountOut, uint256 deadline) external payable;
  function burn() external;
}