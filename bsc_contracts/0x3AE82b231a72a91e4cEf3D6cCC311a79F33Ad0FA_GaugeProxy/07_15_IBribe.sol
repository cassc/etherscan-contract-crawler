// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface IBribe {
    function _deposit(uint256 _amount, address _user) external;
    function _withdraw(uint256 _amount, address _user) external;
    function left(address rewardToken) external view returns (uint256);
    function addReward(address _rewardsToken) external;
    function getRewardForOwner(address _user) external;
    function notifyRewardAmount(address _rewardsToken, uint256 reward) external;
}