// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPool {

    function openFarm() external;

    function distributeBonusRewards(uint256 amount) external;

    function stake(uint256 amount) external;

    function stakeTo(address recipient, uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawTo(address recipient, uint256 amount) external;

    function claimReward() external;

    function claimRewardTo(address recipient) external;

}