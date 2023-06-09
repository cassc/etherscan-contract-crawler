// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IRewards {
    function queueNewRewards(address, uint256) external payable;

    event RewardAdded(address indexed _rewardToken, uint256 _reward);
}