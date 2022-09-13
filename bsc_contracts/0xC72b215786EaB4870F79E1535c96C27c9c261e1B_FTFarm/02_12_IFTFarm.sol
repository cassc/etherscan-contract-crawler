// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFTFarm{
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256) ;

    function getRewardForDuration() external view returns (uint256);

    function getHash(address _address) external view returns(uint256);

    function stake(address _owner,uint256 _amount) external;

    function getReward(uint256 _reward) external;

    function withdraw(address _owner,uint256 _amount) external;

    function notifyRewardAmount(uint256 reward) external;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address user, uint256 amount);
    event Withdrawn(address user, uint256 amount);
}