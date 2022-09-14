// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IStaking {
    struct UserInfo {
        uint256 amount;
        // How much was collected and stored until the current moment,
        // keeps rewards if e.g. user staked a big amount at first and then removed half
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 lastStakedAt;
        uint256 lastUnstakedAt;
    }

    function getUserInfo(address account) external view returns (UserInfo memory);

    function pendingRewards(address account) external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function claim() external;
}