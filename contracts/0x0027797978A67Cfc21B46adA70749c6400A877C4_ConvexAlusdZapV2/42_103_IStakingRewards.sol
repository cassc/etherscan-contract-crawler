// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/*
 * Synthetix: StakingRewards.sol
 *
 * Docs: https://docs.synthetix.io/
 *
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2020 Synthetix
 *
 */

interface IStakingRewards {
    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}