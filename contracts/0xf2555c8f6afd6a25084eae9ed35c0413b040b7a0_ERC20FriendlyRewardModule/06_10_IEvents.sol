/*
IEvents

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.4;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUnlocked(address indexed token, uint256 shares);
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
}