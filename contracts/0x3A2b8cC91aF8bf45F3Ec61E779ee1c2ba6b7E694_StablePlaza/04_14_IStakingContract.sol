// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title StablePlaza staking interface
 * @author Jazzer9F
 */
interface IStakingContract {

 /**
  * @notice Stake configured staking token to receive a split of the the trading fee in return.
  * @param amountToStake Amount of tokens to stake
  * @param voluntaryLockupTime A voluntary lockup period to receive a fee splitting bonus.
  * Please note that it is impossible to unstake before the `voluntaryLockupTime` has expired.
  */
  function stake(
    uint256 amountToStake,
    uint32 voluntaryLockupTime
  ) external;

 /**
  * @notice Unstake tokens that have previously been staked. Rewards are in LP tokens.
  * @dev Only possible if the optional `voluntaryLockupTime` has expired.
  * @param amountToUnstake Amount of tokens to unstake
  */
  function unstake(
    uint256 amountToUnstake
  ) external;

 /**
  * @notice Emit Staked event when new tokens are staked
  * @param staker Address of the caller
  * @param stakedAmount Amount of tokens staked
  * @param sharesEquivalent The amount of tokens staked plus any bonuses due to voluntary locking
  */
  event Staked(
    address staker,
    uint256 stakedAmount,
    uint64 sharesEquivalent
  );

 /**
  * @notice Emit Unstaked event when new tokens are unstaked
  * @param staker Address of the caller
  * @param unstakedAmount Amount of tokens unstaked
  * @param sharesDestroyed The amount of tokens unstaked plus any bonuses due to voluntary locking
  * @param rewards Staking rewards in LP tokens returned to the caller
  */
  event Unstaked(
    address staker,
    uint256 unstakedAmount,
    uint64 sharesDestroyed,
    uint256 rewards
  );
}