// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBoost {
    function getAmountNeedLocked(
        address user,
        uint256 userStakedAmount,
        uint256 totalStakedAmount
    ) external view returns (uint256);

    function userLockStatus(address user) external view returns (uint256, uint256, uint256, uint256);

    function getUserBoost(address user, uint256 userUpdatedAt, uint256 finishAt) external view returns (uint256);

    function getUnlockTime(address user) external view returns (uint256 unlockTime);
}