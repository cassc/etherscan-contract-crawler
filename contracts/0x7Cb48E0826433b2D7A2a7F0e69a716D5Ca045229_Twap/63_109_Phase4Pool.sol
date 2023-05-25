// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./extensions/LockInPool.sol";

/**
 * Phase4Pool that acts as a SNX Reward Contract, with an 8 day token lock.
 */
contract Phase4Pool is LockInPool {
  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Phase4Pool
   * @param _admin The default role controller
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   * @param _duration Duration for token
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration
  )
    BasePool(
      _admin,
      _rewardDistribution,
      _rewardToken,
      _stakingToken,
      _duration
    )
  {}
}