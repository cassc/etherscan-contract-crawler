/*
IERC20FriendlyRewardModuleV2

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Friendly reward module interface
 *
 * @notice this declares the interface for the v2 friendly reward module
 * to provide backwards compatibility in the pool info system
 */
interface IERC20FriendlyRewardModuleV2 {
    // -- IRewardModule -------------------------------------------------------
    function tokens() external view returns (address[] memory);

    function balances() external view returns (uint256[] memory);

    function usage() external view returns (uint256);

    function factory() external view returns (address);

    // -- IERC20FriendlyRewardModuleV2 ----------------------------------------

    function totalStakingShares() external view returns (uint256);

    function totalRawStakingShares() external view returns (uint256);

    function rewardsPerStakedShare() external view returns (uint256);

    function rewardDust() external view returns (uint256);

    function totalShares(address) external view returns (uint256);

    function lockedShares(address) external view returns (uint256);

    function fundingCount(address) external view returns (uint256);

    function unlockable(address, uint256) external view returns (uint256);

    function totalUnlocked() external view returns (uint256);

    function stakeCount(address) external view returns (uint256);

    function stakes(
        address,
        uint256
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function timeVestingCoefficient(uint256) external view returns (uint256);
}