/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IConvexRewardPool {
    function rewardToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 idx) external view returns (address);

    function getReward(address _user, bool _extra) external returns (bool);

    function stake(uint256 _amount) external returns (bool);

    function withdraw(uint256 _amount, bool _claim) external returns (bool);
}