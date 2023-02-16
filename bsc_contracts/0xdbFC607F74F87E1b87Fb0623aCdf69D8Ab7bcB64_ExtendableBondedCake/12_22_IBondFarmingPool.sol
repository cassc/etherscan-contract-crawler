// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IBondFarmingPool {
    function stake(uint256 amount_) external;

    function stakeForUser(address user_, uint256 amount_) external;

    function updatePool() external;

    function totalPendingRewards() external view returns (uint256);

    function lastUpdatedPoolAt() external view returns (uint256);

    function setSiblingPool(IBondFarmingPool siblingPool_) external;

    function siblingPool() external view returns (IBondFarmingPool);
}