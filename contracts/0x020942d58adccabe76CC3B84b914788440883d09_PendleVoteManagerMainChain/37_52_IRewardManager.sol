// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IRewardManager {
    function userReward(
        address token,
        address user
    ) external view returns (uint128 index, uint128 accrued);
}