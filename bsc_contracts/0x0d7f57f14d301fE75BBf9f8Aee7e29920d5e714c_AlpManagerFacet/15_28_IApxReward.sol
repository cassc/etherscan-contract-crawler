// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IApxReward {

    struct ApxPoolInfo {
        uint256 totalStaked;
        uint256 apxPerBlock;        //award per block
        uint256 lastRewardBlock;   // Last block number that APXs distribution occurs.
        uint256 accAPXPerShare;    // Accumulated APXs per share, times 1e12. See below.
        uint256 totalReward;
        uint256 reserves;
    }

    struct ApxUserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 pendingReward; // User pending reward
        //
        // We do some fancy math here. Basically, any point in time, the amount of APXs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accAPXPerShare) - user.rewardDebt + user.rewardPending
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accAPXPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User's `pendingReward` gets updated.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    function updateApxPerBlock(uint256 apxPerBlock) external;

    function addReserves(uint256 amount) external;

    function apxPoolInfo() external view returns (ApxPoolInfo memory) ;

    function pendingApx(address _account) external view returns (uint256);
}