// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 

interface ISpumeRewardPool {
    function deposit(uint256 amount) external;
    function rewardSwap(uint256 _rewardTokenAmount) external;
    function rewardClaimAndSwap() external; 
    function pauseRewardPool() external;
    function unPauseRewardPool() external;
    function setDepositor(address newDepositor) external; 
    function removeDepositor(address newDepositor) external;
}