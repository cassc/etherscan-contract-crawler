// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILiquidDepositor {
  function treasury() external view returns (address);
  function setDistributionRate(uint256 amount) external;
}