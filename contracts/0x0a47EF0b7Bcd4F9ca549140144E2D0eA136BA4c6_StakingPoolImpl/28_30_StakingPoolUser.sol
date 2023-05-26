// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

/// @title Interaction between a pool user and a pool
/// @author Danilo Tuler
/// @notice This interface models all interactions between a pool user and a pool,
/// including staking, unstaking and withdrawing. A pool user always holds pool shares.
/// When a user stakes tokens, he immediately receive shares. When he unstakes shares
/// he is asking to release tokens. Those tokens need to be withdrawn by an additional
/// call to withdraw()
interface StakingPoolUser {
    /// @notice Deposit tokens to user pool balance
    /// @param amount amount of token deposited in the pool
    function deposit(uint256 amount) external;

    /// @notice Stake an amount of tokens, immediately earning pool shares in returns
    /// @param amount amount of tokens to convert to shares
    function stake(uint256 amount) external;

    /// @notice Unstake an specified amount of shares of the calling user
    /// @dev Shares are immediately converted to tokens, and added to the pool liquidity requirement
    function unstake(uint256 shares) external;

    /// @notice Transfer tokens back to calling user wallet
    /// @dev this will transfer tokens from user pool account to user's wallet
    function withdraw(uint256 amount) external;

    /// @notice Returns the amount of tokens that can be immediately withdrawn by the calling user
    /// @dev there is no way to know the exact time in the future the requested tokens will be available
    /// @return the amount of tokens that can be immediately withdrawn by the calling user
    function getWithdrawBalance() external returns (uint256);

    /// @notice Tokens were deposited, available for staking or withdrawal
    /// @param user address of msg.sender
    /// @param amount amount of tokens deposited by the user
    /// @param stakeTimestamp instant when the amount can be staked
    event Deposit(address indexed user, uint256 amount, uint256 stakeTimestamp);

    /// @notice Tokens were deposited, they count as shares immediatly
    /// @param user address of msg.sender
    /// @param amount amount deposited by the user
    /// @param shares number of shares emitted for user
    event Stake(address indexed user, uint256 amount, uint256 shares);

    /// @notice Request to unstake tokens. Additional liquidity requested for the pool
    /// @param user address of msg.sender
    /// @param amount amount of tokens to be released
    /// @param shares number of shares being liquidated
    event Unstake(address indexed user, uint256 amount, uint256 shares);

    /// @notice Withdraw performed by a user
    /// @param user address of msg.sender
    /// @param amount amount of tokens withdrawn
    event Withdraw(address indexed user, uint256 amount);
}