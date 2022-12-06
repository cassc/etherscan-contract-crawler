// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface INftReflection {
    struct UserInfo {
        uint256 totalGgymnetAmt;
        uint256 rewardsClaimt;
        uint256 rewardDebt;
    }

    function pendingReward(address) external view returns (uint256);

    function updateUser(
        uint256,
        address
    ) external;
    function updatePool(
        uint256
    ) external;
}