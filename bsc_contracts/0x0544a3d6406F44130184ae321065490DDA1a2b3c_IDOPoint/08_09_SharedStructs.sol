// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SharedStructs {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }
}