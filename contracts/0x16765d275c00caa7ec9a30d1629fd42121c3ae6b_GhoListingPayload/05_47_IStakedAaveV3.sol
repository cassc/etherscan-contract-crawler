// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IStakedTokenV3} from './IStakedTokenV3.sol';
import {IGhoVariableDebtTokenTransferHook} from './IGhoVariableDebtTokenTransferHook.sol';

interface IStakedAaveV3 is IStakedTokenV3 {
  struct ExchangeRateSnapshot {
    uint40 blockNumber;
    uint216 value;
  }

  event GHODebtTokenChanged(address indexed newDebtToken);

  /**
   * @dev Sets the GHO debt token (only callable by SHORT_EXECUTOR)
   * @param newGHODebtToken Address to GHO debt token
   */
  function setGHODebtToken(IGhoVariableDebtTokenTransferHook newGHODebtToken)
    external;

  /**
   * @dev Claims an `amount` of `REWARD_TOKEN` and stakes.
   * @param to Address to stake to
   * @param amount Amount to claim
   */
  function claimRewardsAndStake(address to, uint256 amount)
    external
    returns (uint256);

  /**
   * @dev Claims an `amount` of `REWARD_TOKEN` and stakes. Only the claim helper contract is allowed to call this function
   * @param from The address of the from from which to claim
   * @param to Address to stake to
   * @param amount Amount to claim
   */
  function claimRewardsAndStakeOnBehalf(
    address from,
    address to,
    uint256 amount
  ) external returns (uint256);

  /**
   * @dev Allows staking a certain amount of STAKED_TOKEN with gasless approvals (permit)
   * @param from The address staking the token
   * @param amount The amount to be staked
   * @param deadline The permit execution deadline
   * @param v The v component of the signed message
   * @param r The r component of the signed message
   * @param s The s component of the signed message
   */
  function stakeWithPermit(
    address from,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}