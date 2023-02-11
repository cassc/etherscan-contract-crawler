// SPDX-License-Identifier: Apache 2.0
/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020-2022 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "../staking_pools/MixinStakingPool.sol";

abstract contract MixinStake is MixinStakingPool {
    /// @inheritdoc IStaking
    function stake(uint256 amount) external override {
        address staker = msg.sender;

        // deposit equivalent amount of GRG into vault
        getGrgVault().depositFrom(staker, amount);

        // mint stake
        _increaseCurrentAndNextBalance(_ownerStakeByStatus[uint8(IStructs.StakeStatus.UNDELEGATED)][staker], amount);

        // notify
        emit Stake(staker, amount);
    }

    /// @inheritdoc IStaking
    function unstake(uint256 amount) external override {
        address staker = msg.sender;

        IStructs.StoredBalance memory undelegatedBalance = _loadCurrentBalance(
            _ownerStakeByStatus[uint8(IStructs.StakeStatus.UNDELEGATED)][staker]
        );

        // stake must be undelegated in current and next epoch to be withdrawn
        uint256 currentWithdrawableStake = undelegatedBalance.currentEpochBalance < undelegatedBalance.nextEpochBalance
            ? undelegatedBalance.currentEpochBalance
            : undelegatedBalance.nextEpochBalance;

        require(amount <= currentWithdrawableStake, "MOVE_STAKE_AMOUNT_HIGHER_THAN_WITHDRAWABLE_ERROR");

        // burn undelegated stake
        _decreaseCurrentAndNextBalance(_ownerStakeByStatus[uint8(IStructs.StakeStatus.UNDELEGATED)][staker], amount);

        // withdraw equivalent amount of GRG from vault
        getGrgVault().withdrawFrom(staker, amount);

        // emit stake event
        emit Unstake(staker, amount);
    }

    /// @inheritdoc IStaking
    function moveStake(
        IStructs.StakeInfo calldata from,
        IStructs.StakeInfo calldata to,
        uint256 amount
    ) external override {
        address staker = msg.sender;

        // Sanity check: no-op if no stake is being moved.
        require(amount != 0, "MOVE_STAKE_AMOUNT_NULL_ERROR");

        // Sanity check: no-op if moving stake from undelegated to undelegated.
        if (from.status == IStructs.StakeStatus.UNDELEGATED && to.status == IStructs.StakeStatus.UNDELEGATED) {
            revert("MOVE_STAKE_UNDELEGATED_STATUS_UNCHANGED_ERROR");
        }

        // handle delegation
        if (from.status == IStructs.StakeStatus.DELEGATED) {
            _undelegateStake(from.poolId, staker, amount);
        }

        if (to.status == IStructs.StakeStatus.DELEGATED) {
            _delegateStake(to.poolId, staker, amount);
        }

        // execute move
        IStructs.StoredBalance storage fromPtr = _ownerStakeByStatus[uint8(from.status)][staker];
        IStructs.StoredBalance storage toPtr = _ownerStakeByStatus[uint8(to.status)][staker];
        _moveStake(fromPtr, toPtr, amount);

        // notify
        emit MoveStake(staker, amount, uint8(from.status), from.poolId, uint8(to.status), to.poolId);
    }

    /// @dev Delegates a owners stake to a staking pool.
    /// @param poolId Id of pool to delegate to.
    /// @param staker Owner who wants to delegate.
    /// @param amount Amount of stake to delegate.
    function _delegateStake(
        bytes32 poolId,
        address staker,
        uint256 amount
    ) private {
        // Sanity check the pool we're delegating to exists.
        _assertStakingPoolExists(poolId);

        _withdrawAndSyncDelegatorRewards(poolId, staker);

        // Increase how much stake the staker has delegated to the input pool.
        _increaseNextBalance(_delegatedStakeToPoolByOwner[staker][poolId], amount);

        // Increase how much stake has been delegated to pool.
        _increaseNextBalance(_delegatedStakeByPoolId[poolId], amount);

        // Increase next balance of global delegated stake.
        _increaseNextBalance(_globalStakeByStatus[uint8(IStructs.StakeStatus.DELEGATED)], amount);
    }

    /// @dev Un-Delegates a owners stake from a staking pool.
    /// @param poolId Id of pool to un-delegate from.
    /// @param staker Owner who wants to un-delegate.
    /// @param amount Amount of stake to un-delegate.
    function _undelegateStake(
        bytes32 poolId,
        address staker,
        uint256 amount
    ) private {
        // sanity check the pool we're undelegating from exists
        _assertStakingPoolExists(poolId);

        _withdrawAndSyncDelegatorRewards(poolId, staker);

        // Decrease how much stake the staker has delegated to the input pool.
        _decreaseNextBalance(_delegatedStakeToPoolByOwner[staker][poolId], amount);

        // Decrease how much stake has been delegated to pool.
        _decreaseNextBalance(_delegatedStakeByPoolId[poolId], amount);

        // Decrease next balance of global delegated stake (aggregated across all stakers).
        _decreaseNextBalance(_globalStakeByStatus[uint8(IStructs.StakeStatus.DELEGATED)], amount);
    }
}