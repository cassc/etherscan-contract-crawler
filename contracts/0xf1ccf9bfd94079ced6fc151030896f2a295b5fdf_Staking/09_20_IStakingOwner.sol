// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @notice Owner functions restricted to the setup and maintenance
/// of the staking contract by the owner.
interface IStakingOwner {
    /// @notice This error is thrown when an zero delegation rate is supplied
    error InvalidDelegationRate();

    /// @notice This error is thrown when an invalid operator stake amount is
    /// supplied
    error InvalidOperatorStakeAmount();

    /// @notice This error is thrown when an invalid min community stake amount
    /// is supplied
    error InvalidMinCommunityStakeAmount();

    /// @notice This error is thrown when the reward is already initialized
    error AlreadyInitialized();

    /// @notice Adds one or more operators to a list of operators
    /// @dev Should only callable by the Owner
    /// @param operators A list of operator addresses to add
    function addOperators(address[] calldata operators) external;

    /// @notice This function can be called to add rewards to the pool when the reward is depleted
    /// @dev Should only callable by the Owner
    /// @param amount The amount of rewards to add to the pool
    /// @param rewardDuration The duration of the reward
    function newReward(uint256 amount, uint256 rewardDuration) external;

    /// @notice This function can be called to add rewards to the pool when the reward is not depleted
    /// @dev Should only be callable by the owner
    /// @param amount The amount of rewards to add to the pool
    /// @param rewardDuration The duration of the reward
    function addReward(uint256 amount, uint256 rewardDuration) external;

    /// @notice Set the pool config
    /// @param maxPoolSize The max amount of staked ARPA by community stakers allowed in the pool
    /// @param maxCommunityStakeAmount The max amount of ARPA a community staker can stake
    function setPoolConfig(uint256 maxPoolSize, uint256 maxCommunityStakeAmount) external;

    /// @notice Set controller contract address
    /// @dev Should only be callable by the owner
    /// @param controller The address of the controller contract
    function setController(address controller) external;

    /// @notice Transfers ARPA tokens and initializes the reward
    /// @dev Uses ERC20 approve + transferFrom flow
    /// @param amount rewards amount in ARPA
    /// @param rewardDuration rewards duration in seconds
    function start(uint256 amount, uint256 rewardDuration) external;

    /// @notice This function pauses staking
    /// @dev Sets the pause flag to true
    function emergencyPause() external;

    /// @notice This function unpauses staking
    /// @dev Sets the pause flag to false
    function emergencyUnpause() external;
}