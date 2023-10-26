// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRewardsManager {
    receive() external payable;

    // GETTER FUNCTIONS
    function totalRewards() external view returns (uint256);

    function rewardsPool() external view returns (uint256);

    function updateRewards(uint256 _newRewards) external;
}