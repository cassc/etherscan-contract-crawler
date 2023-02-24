// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface ICvxRewardPool {
    function balanceOf(address account) external view returns (uint256);

    function duration() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function getReward(bool stake) external returns (bool);

    function getReward(
        address _account,
        bool _claimExtras,
        bool stake
    ) external returns (bool);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;
}