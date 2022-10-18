// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IWTFRewards {
    struct Pool {
        uint256 accRewardPerShare;
        uint256 startRewardBlock;
        uint256 endRewardBlock;
        uint256 lastRewardBlock;
        uint256 rewardPerBlock;
        uint256 totalStaked;
    }
    struct User {
        uint256 amount;
        uint256 rewardDebt;
    }

    function pool() external returns (Pool memory);

    function lastRewardBlock() external view returns (uint256);

    function rewardPerShare() external view returns (uint256);

    function getAccountData(address account)
        external
        view
        returns (User memory user);

    function users(address user) external returns (User memory);

    function totalStaked() external view returns (uint256);
}