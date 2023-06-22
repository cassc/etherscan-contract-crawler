/*
IERC20CompetitiveRewardModuleV2

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Competitive reward module interface
 *
 * @notice this declares the interface for the v2 competitive reward module
 * to provide backwards compatibility in the pool info system
 */
interface IERC20CompetitiveRewardModuleV2 {
    // -- IRewardModule -------------------------------------------------------
    function tokens() external view returns (address[] memory);

    function balances() external view returns (uint256[] memory);

    function usage() external view returns (uint256);

    function factory() external view returns (address);

    // -- IERC20CompetitiveRewardModuleV2 -------------------------------------

    function totalStakingShares() external view returns (uint256);

    function totalStakingShareSeconds() external view returns (uint256);

    function lockedShares(address) external view returns (uint256);

    function fundingCount(address) external view returns (uint256);

    function unlockable(address, uint256) external view returns (uint256);

    function totalLocked() external view returns (uint256);

    function totalUnlocked() external view returns (uint256);

    function stakeCount(address) external view returns (uint256);

    function stakes(address, uint256) external view returns (uint256, uint256);

    function timeBonus(uint256) external view returns (uint256);

    function lastUpdated() external view returns (uint256);
}