// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken1() external view returns (uint256);

    function rewardPerToken2() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function earned2(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getRewards() external;

    function exit() external;
}