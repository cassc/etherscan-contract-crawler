// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IStakingPoolRewarder {
    function onReward(
        uint256 poolId,
        address user,
        uint256 amount
    ) external;
}