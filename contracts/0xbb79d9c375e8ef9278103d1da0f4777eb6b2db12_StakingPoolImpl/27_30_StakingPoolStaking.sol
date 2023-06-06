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

/// @title Interaction between a pool and the staking contract
/// @author Danilo Tuler
/// @notice This interface models all interactions between a pool and the staking contract,
/// including staking, unstaking and withdrawing.
/// Tokens staked by pool users will stay at the pool until the pool owner decides to
/// stake them in the staking contract. On the other hand, tokens unstaked by pool users
/// are added to a required liquidity accumulator, and must be unstaked and withdrawn from
/// the staking contract.
interface StakingPoolStaking {
    /// @notice Move tokens from pool to staking or vice-versa, according to required liquidity.
    /// If the pool has more liquidity then necessary, it stakes tokens.
    /// If the pool has less liquidity then necessary, and has not started an unstake, it unstakes.
    /// If the pool has less liquity than necessary, and has started an unstake, it withdraws if possible.
    function rebalance() external;

    /// @notice provide information for offchain about the amount for each
    /// staking operation on the main Staking contract
    /// @return stake amount of tokens that can be staked
    /// @return unstake amount of tokens that must be unstaked to add liquidity
    /// @return withdraw amount of tokens that can be withdrawn to add liquidity
    function amounts()
        external
        view
        returns (
            uint256 stake,
            uint256 unstake,
            uint256 withdraw
        );
}