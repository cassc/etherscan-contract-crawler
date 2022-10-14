// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "IERC20.sol";

// Full fork from:
// Angle Protocol's IStakingRewards
// https://github.com/AngleProtocol/angle-core/blob/main/contracts/interfaces/IStakingRewards.sol

/// @title IStakingRewardsFunctions
/// @author Forked from contracts developed by Angle and adapted by DFX
/// - IStakingRewards.sol (https://github.com/AngleProtocol/angle-core/blob/main/contracts/interfaces/IStakingRewards.sol)
/// @notice Interface for the staking rewards contract that interact with the `RewardsDistributor` contract
interface IStakingRewardsFunctions {
    function notifyRewardAmount(uint256 reward) external;

    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 tokenAmount
    ) external;

    function setNewRewardsDistribution(address newRewardsDistribution) external;
}

/// @title IStakingRewards
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables
interface IStakingRewards is IStakingRewardsFunctions {
    function rewardToken() external view returns (IERC20);
}