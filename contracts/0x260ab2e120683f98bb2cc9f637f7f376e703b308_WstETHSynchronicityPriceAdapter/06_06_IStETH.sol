// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IStETH {
  function getPooledEthByShares(uint256 shares) external view returns (uint256);
}