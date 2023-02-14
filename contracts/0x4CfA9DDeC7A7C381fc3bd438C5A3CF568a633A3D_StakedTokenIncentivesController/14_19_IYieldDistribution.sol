// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IYieldDistribution {
  /**
   * @dev Called by the incentiveController or vault on any update that affects the rewards distribution
   * @param user The address of the user
   * @param asset The address of the sToken
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
  function handleAction(
    address user,
    address asset,
    uint256 totalSupply,
    uint256 userBalance
  ) external;
}