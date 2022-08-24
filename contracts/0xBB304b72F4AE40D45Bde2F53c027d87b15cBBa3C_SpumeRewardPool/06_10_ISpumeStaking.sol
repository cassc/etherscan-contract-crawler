// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 

interface ISpumeStaking { 
    function stake(uint256 amount)external;
    function unstake(uint256 amount) external;
    function rewardPerToken() external returns (uint256); 
    function claimReward(address claimer) external returns (uint256);
    function depositRewardToken(uint256 amount) external;
    function getStaked(address account) external returns (uint256);
    function getCreatedAt() external view returns (uint256); 
    function getStakedTotalSupply() external view returns (uint256);
}