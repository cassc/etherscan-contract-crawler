// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IStaking {
  /// @notice This event is emitted when a staker adds stake to the pool.
  /// @param staker Staker address
  /// @param newStake New principal amount staked
  /// @param totalStake Total principal amount staked
  event Staked(address staker, uint256 newStake, uint256 totalStake);
  /// @notice This event is emitted when a staker exits the pool.
  /// @param staker Staker address
  /// @param principal Principal amount staked
  /// @param baseReward base reward earned
  /// @param delegationReward delegation reward earned, if any
  event Unstaked(
    address staker,
    uint256 principal,
    uint256 baseReward,
    uint256 delegationReward
  );

  /// @notice This error is thrown whenever the sender is not the LINK token
  error SenderNotLinkToken();

  /// @notice This error is thrown whenever an address does not have access
  /// to successfully execute a transaction
  error AccessForbidden();

  /// @notice This error is thrown whenever a zero-address is supplied when
  /// a non-zero address is required
  error InvalidZeroAddress();

  /// @notice This function allows stakers to exit the pool after it has been
  /// concluded. It returns the principal as well as base and delegation
  /// rewards.
  function unstake() external;

  /// @notice This function allows removed operators to withdraw their original
  /// principal. Operators can only withdraw after the pool is closed, like
  /// every other staker.
  function withdrawRemovedStake() external;

  /// @return address LINK token contract's address that is used by the pool
  function getChainlinkToken() external view returns (address);

  /// @param staker address
  /// @return uint256 staker's staked principal amount
  function getStake(address staker) external view returns (uint256);

  /// @notice Returns true if an address is an operator
  function isOperator(address staker) external view returns (bool);

  /// @notice The staking pool starts closed and only allows
  /// stakers to stake once it's opened
  /// @return bool pool status
  function isActive() external view returns (bool);

  /// @return uint256 current maximum staking pool size
  function getMaxPoolSize() external view returns (uint256);

  /// @return uint256 minimum amount that can be staked by a community staker
  /// @return uint256 maximum amount that can be staked by a community staker
  function getCommunityStakerLimits() external view returns (uint256, uint256);

  /// @return uint256 minimum amount that can be staked by an operator
  /// @return uint256 maximum amount that can be staked by an operator
  function getOperatorLimits() external view returns (uint256, uint256);

  /// @return uint256 reward initialization timestamp
  /// @return uint256 reward expiry timestamp
  function getRewardTimestamps() external view returns (uint256, uint256);

  /// @return uint256 current reward rate, expressed in juels per second per micro LINK
  function getRewardRate() external view returns (uint256);

  /// @return uint256 current delegation rate
  function getDelegationRateDenominator() external view returns (uint256);

  /// @return uint256 total amount of LINK tokens made available for rewards in
  /// Juels
  /// @dev This reflects how many rewards were made available over the
  /// lifetime of the staking pool. This is not updated when the rewards are
  /// unstaked or migrated by the stakers. This means that the contract balance
  /// will dip below available amount when the reward expires and users start
  /// moving their rewards.
  function getAvailableReward() external view returns (uint256);

  /// @return uint256 amount of base rewards earned by a staker in Juels
  function getBaseReward(address) external view returns (uint256);

  /// @return uint256 amount of delegation rewards earned by an operator in Juels
  function getDelegationReward(address) external view returns (uint256);

  /// @notice Total delegated amount is calculated by dividing the total
  /// community staker staked amount by the delegation rate, i.e.
  /// totalDelegatedAmount = pool.totalCommunityStakedAmount / delegationRateDenominator
  /// @return uint256 staked amount that is used when calculating delegation rewards in Juels
  function getTotalDelegatedAmount() external view returns (uint256);

  /// @notice Delegates count increases after an operator is added to the list
  /// of operators and stakes the minimum required amount.
  /// @return uint256 number of staking operators that are eligible for delegation rewards
  function getDelegatesCount() external view returns (uint256);

  /// @return uint256 total amount of base rewards earned by all stakers in Juels
  function getEarnedBaseRewards() external view returns (uint256);

  /// @return uint256 total amount of delegated rewards earned by all node operators in Juels
  function getEarnedDelegationRewards() external view returns (uint256);

  /// @return uint256 total amount staked by community stakers and operators in Juels
  function getTotalStakedAmount() external view returns (uint256);

  /// @return uint256 total amount staked by community stakers in Juels
  function getTotalCommunityStakedAmount() external view returns (uint256);

  /// @return uint256 the sum of removed operator principals that have not been
  /// withdrawn from the staking pool in Juels.
  /// @dev Used to make sure that contract's balance is correct.
  /// total staked amount + total removed amount + available rewards = current balance
  function getTotalRemovedAmount() external view returns (uint256);

  /// @notice This function returns the pause state
  /// @return bool whether or not the pool is paused
  function isPaused() external view returns (bool);

  /// @return address The address of the feed being monitored to raise alerts for
  function getMonitoredFeed() external view returns (address);
}