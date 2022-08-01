// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IRewardDistributor {
    function totalRewardsDistributed() external view returns (uint256);
    function distributeReward(address account,uint256 amount) external returns (bool);
}