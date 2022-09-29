// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IStakingPool {
    function getCompounderPercent() external view returns(uint256);
    function initalizePool(uint256 blockNum) external;
    function deliverReward(uint256 round, uint256 index, uint256 amount) external;
    function getCurrentRound() external view returns(uint256);
    function calculateShare(address user, uint256 round, uint256 index) external view returns(uint256);
}