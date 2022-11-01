// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStargatePool {
  function decimals() external view returns (uint8);
  function totalLiquidity() external view returns (uint);
  function totalSupply() external view returns (uint);
}