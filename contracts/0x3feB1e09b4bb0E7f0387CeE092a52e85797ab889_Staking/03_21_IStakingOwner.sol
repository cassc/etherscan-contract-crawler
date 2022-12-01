// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @notice Owner functions restricted to the setup and maintenance
/// of the staking contract by the owner.
interface IStakingOwner {
  /// @notice This error is thrown when an zero delegation rate is supplied
  error InvalidDelegationRate();

  /// @notice This error is thrown when an invalid regular period threshold is supplied
  error InvalidRegularPeriodThreshold();

  /// @notice This error is thrown when an invalid min operator stake amount is
  /// supplied
  error InvalidMinOperatorStakeAmount();

  /// @notice This error is thrown when an invalid min community stake amount
  /// is supplied
  error InvalidMinCommunityStakeAmount();

  /// @notice This error is thrown when an invalid max alerting reward is
  /// supplied
  error InvalidMaxAlertingRewardAmount();

  /// @notice This error is thrown when the pool is started with an empty
  /// merkle root
  error MerkleRootNotSet();

  /// @notice Adds one or more operators to a list of operators
  /// @dev Should only callable by the Owner
  /// @param operators A list of operator addresses to add
  function addOperators(address[] calldata operators) external;

  /// @notice Removes one or more operators from a list of operators. When an
  /// operator is removed, we store their principal in a separate mapping to
  /// prevent immediate withdrawals. This is so that the removed operator can
  /// only unstake at the same time as every other staker.
  /// @dev Should only be callable by the owner when the pool is open.
  /// When an operator is removed they can stake as a community staker.
  /// We allow that because the alternative (checking for removed stake before
  /// staking) is going to unnecessarily increase gas costs in 99.99% of the
  /// cases.
  /// @param operators A list of operator addresses to remove
  function removeOperators(address[] calldata operators) external;

  /// @notice Allows the contract owner to set the list of on-feed operator addresses who are subject to slashing
  /// @dev Existing feed operators are cleared before setting the new operators.
  /// @param operators New list of on-feed operator staker addresses
  function setFeedOperators(address[] calldata operators) external;

  /// @return List of the ETH-USD feed node operators' staking addresses
  function getFeedOperators() external view returns (address[] memory);

  /// @notice This function can be called to change the reward rate for the pool.
  /// This change only affects future rewards, i.e. rewards earned at a previous
  /// rate are unaffected.
  /// @dev Should only be callable by the owner. The rate can be increased or decreased.
  /// The new rate cannot be 0.
  /// @param rate The new reward rate
  function changeRewardRate(uint256 rate) external;

  /// @notice This function can be called to add rewards to the pool
  /// @dev Should only be callable by the owner
  /// @param amount The amount of rewards to add to the pool
  function addReward(uint256 amount) external;

  /// @notice This function can be called to withdraw unused reward amount from
  /// the staking pool. It can be called before the pool is initialized, after
  /// the pool is concluded or when the reward expires.
  /// @dev Should only be callable by the owner when the pool is closed
  function withdrawUnusedReward() external;

  /// @notice Set the pool config
  /// @param maxPoolSize The max amount of staked LINK allowed in the pool
  /// @param maxCommunityStakeAmount The max amount of LINK a community staker can stake
  /// @param maxOperatorStakeAmount The max amount of LINK a Node Op can stake
  function setPoolConfig(
    uint256 maxPoolSize,
    uint256 maxCommunityStakeAmount,
    uint256 maxOperatorStakeAmount
  ) external;

  /// @notice Transfers LINK tokens and initializes the reward
  /// @dev Uses ERC20 approve + transferFrom flow
  /// @param amount rewards amount in LINK
  /// @param initialRewardRate The amount of LINK earned per second for
  /// each LINK staked.
  function start(uint256 amount, uint256 initialRewardRate) external;

  /// @notice Closes the pool, unreserving future staker rewards, expires the
  /// reward and releases unreserved rewards
  function conclude() external;

  /// @notice This function pauses staking
  /// @dev Sets the pause flag to true
  function emergencyPause() external;

  /// @notice This function unpauses staking
  /// @dev Sets the pause flag to false
  function emergencyUnpause() external;
}