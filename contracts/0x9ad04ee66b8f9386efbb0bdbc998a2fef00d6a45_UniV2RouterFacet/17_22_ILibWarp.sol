// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILibWarp {
  event Warp(
    address indexed partner,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );
}