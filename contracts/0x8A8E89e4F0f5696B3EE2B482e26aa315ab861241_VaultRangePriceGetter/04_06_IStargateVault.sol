// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStargateVault {
  function decimals() external view returns (uint8);
  function previewWithdraw(uint assets) external view returns (uint);
}