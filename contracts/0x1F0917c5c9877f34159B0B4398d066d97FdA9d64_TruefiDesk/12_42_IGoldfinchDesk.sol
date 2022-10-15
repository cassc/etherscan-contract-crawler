// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGoldfinchDesk {
  /**
   * @notice GoldFinch PoolToken Value in Value in term of USDC
   */
  function getGoldFinchPoolTokenBalanceInUsdc() external view returns (uint256);
}