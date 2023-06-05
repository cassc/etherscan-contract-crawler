// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPoolRewards {
    function claimReward(address) external;

    function updateReward(address) external;

    function getRewardTokens() external view returns (address[] memory);
}