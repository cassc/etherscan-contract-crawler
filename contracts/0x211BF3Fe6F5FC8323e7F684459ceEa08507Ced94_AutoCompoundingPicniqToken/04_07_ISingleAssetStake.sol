// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISingleAssetStake {
    function rewardToken() external view returns (address);
    function stakingToken() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function stake(uint256 amount) external payable;
    function withdraw(uint256 amount) external payable;
    function getReward() external;
    function exit() external;
    function notifyRewardAmount(uint256 reward) external payable;
}