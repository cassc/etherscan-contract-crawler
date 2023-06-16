// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILendingPool {
  function toggleWhitelistCollateralPool(address pool) external;
}