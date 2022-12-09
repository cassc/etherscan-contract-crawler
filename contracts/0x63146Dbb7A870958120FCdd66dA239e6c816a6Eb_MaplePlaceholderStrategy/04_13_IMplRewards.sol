// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title MplRewards Synthetix farming contract fork for liquidity mining.
interface IMplRewards {
  /**
        @dev   Emits an event indicating that a reward was added.
        @param reward The amount of the added reward.
     */
  event RewardAdded(uint256 reward);

  /**
        @dev   Emits an event indicating that an account has staked.
        @param account The address of the account.
        @param amount  The amount staked.
     */
  event Staked(address indexed account, uint256 amount);

  /**
        @dev   Emits an event indicating that reward was withdrawn.
        @param account The address of the account.
        @param amount  The amount withdrawn.
     */
  event Withdrawn(address indexed account, uint256 amount);

  /**
        @dev   Emits an event indicating that some reward was paid to an account.
        @param account The address of the account rewarded.
        @param reward  The amount rewarded to `account`.
     */
  event RewardPaid(address indexed account, uint256 reward);

  /**
        @dev   Emits an event indicating that the duration of the ward period has updated.
        @param newDuration The new duration of the rewards.
     */
  event RewardsDurationUpdated(uint256 newDuration);

  /**
        @dev   Emits an event indicating that some token was recovered.
        @param token  The address of the token recovered.
        @param amount The amount recovered.
     */
  event Recovered(address token, uint256 amount);

  /**
        @dev   Emits an event indicating that pause state has changed.
        @param isPaused Whether the contract is paused.
     */
  event PauseChanged(bool isPaused);

  /**
        @dev The rewards token.
     */
  function rewardsToken() external view returns (IERC20);

  /**
        @dev The staking token.
     */
  function stakingToken() external view returns (address);

  /**
        @dev The period finish.
     */
  function periodFinish() external view returns (uint256);

  /**
        @dev The rewards rate.
     */
  function rewardRate() external view returns (uint256);

  /**
        @dev The rewards duration.
     */
  function rewardsDuration() external view returns (uint256);

  /**
        @dev The last update time.
     */
  function lastUpdateTime() external view returns (uint256);

  /**
        @dev The reward per token stored.
     */
  function rewardPerTokenStored() external view returns (uint256);

  /**
        @dev The last pause time.
     */
  function lastPauseTime() external view returns (uint256);

  /**
        @dev Whether the contract is paused.
     */
  function paused() external view returns (bool);

  /**
        @param account The address of an account.
        @return The reward per token paid for `account`.
     */
  function userRewardPerTokenPaid(address account) external view returns (uint256);

  /**
        @param account The address of an account.
        @return The rewards `account`.
     */
  function rewards(address account) external view returns (uint256);

  /**
        @return The total supply.
     */
  function totalSupply() external view returns (uint256);

  /**
        @param account The address of an account.
        @return The balance of `account`.
     */
  function balanceOf(address account) external view returns (uint256);

  /**
        @return The last time rewards were applicable.
     */
  function lastTimeRewardApplicable() external view returns (uint256);

  /**
        @return The reward per token.
     */
  function rewardPerToken() external view returns (uint256);

  /**
        @param account The address of an account.
        @return The rewards earned of `account`.
     */
  function earned(address account) external view returns (uint256);

  /**
        @return The reward for a duration.
     */
  function getRewardForDuration() external view returns (uint256);

  /**
        @dev   It emits a `Staked` event.
        @param amount An amount to stake.
     */
  function stake(uint256 amount) external;

  /**
        @dev   It emits a `Withdrawn` event.
        @param amount An amount to withdraw.
     */
  function withdraw(uint256 amount) external;

  /**
        @dev It emits a `RewardPaid` event if any rewards are received.
     */
  function getReward() external;

  /**
        @dev Withdraw the entire balance and get the reward.
     */
  function exit() external;

  /**
        @dev Only the contract Owner may call this.
        @dev It emits a `RewardAdded` event.
        @param reward A reward amount.
     */
  function notifyRewardAmount(uint256 reward) external;

  /**
        @dev End rewards emission earlier. Only the contract Owner may call this.
        @param timestamp A unix timestamp to finish rewards.
     */
  function updatePeriodFinish(uint256 timestamp) external;

  /**
        @dev Added to support recovering tokens unintentionally sent to this contract.
        @dev Only the contract Owner may call this.
        @dev It emits a `Recovered` event.
        @param tokenAddress The address of a token to recover.
        @param tokenAmount  The amount to recover.
     */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

  /**
        @dev   Only the contract Owner may call this.
        @dev   It emits a `RewardsDurationUpdated` event.
        @param _rewardsDuration The new duration for rewards.
     */
  function setRewardsDuration(uint256 _rewardsDuration) external;

  /**
        @dev Change the paused state of the contract. Only the contract Owner may call this.
        @dev It emits a `PauseChanged` event.
        @param _paused Whether to pause the contract.
     */
  function setPaused(bool _paused) external;
}