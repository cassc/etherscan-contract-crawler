// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IMultiRewarder {
    function stakeFor(
        address pool,
        address account,
        uint256 amount
    ) external;

    function withdrawFrom(
        address pool,
        address account,
        uint256 amount
    ) external;

    function notifyRewardAmount(
        address pool,
        address[] memory _rewardsTokens,
        uint256[] memory _rewards
    ) external;
}