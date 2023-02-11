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

import {IPoolRegistry as PoolRegistry} from "../../protocol/interfaces/IPoolRegistry.sol";
import {IRigoToken as RigoToken} from "../../rigoToken/interfaces/IRigoToken.sol";
import "./IStructs.sol";
import {IGrgVault as GrgVault} from "./IGrgVault.sol";

interface IStaking {
    /// @notice Adds a new proof_of_performance address.
    /// @param addr Address of proof_of_performance contract to add.
    function addPopAddress(address addr) external;

    /// @notice Create a new staking pool. The sender will be the staking pal of this pool.
    /// @dev Note that a staking pal must be payable.
    /// @dev When governance updates registry address, pools must be migrated to new registry, or this contract must query from both.
    /// @param rigoblockPoolAddress Adds rigoblock pool to the created staking pool for convenience if non-null.
    /// @return poolId The unique pool id generated for this pool.
    function createStakingPool(address rigoblockPoolAddress) external returns (bytes32 poolId);

    /// @notice Allows the operator to update the staking pal address.
    /// @param poolId Unique id of pool.
    /// @param newStakingPalAddress Address of the new staking pal.
    function setStakingPalAddress(bytes32 poolId, address newStakingPalAddress) external;

    /// @notice Decreases the operator share for the given pool (i.e. increases pool rewards for members).
    /// @param poolId Unique Id of pool.
    /// @param newOperatorShare The newly decreased percentage of any rewards owned by the operator.
    function decreaseStakingPoolOperatorShare(bytes32 poolId, uint32 newOperatorShare) external;

    /// @notice Begins a new epoch, preparing the prior one for finalization.
    /// @dev Throws if not enough time has passed between epochs or if the
    /// @dev previous epoch was not fully finalized.
    /// @return numPoolsToFinalize The number of unfinalized pools.
    function endEpoch() external returns (uint256 numPoolsToFinalize);

    /// @notice Instantly finalizes a single pool that earned rewards in the previous epoch,
    /// @dev crediting it rewards for members and withdrawing operator's rewards as GRG.
    /// @dev This can be called by internal functions that need to finalize a pool immediately.
    /// @dev Does nothing if the pool is already finalized or did not earn rewards in the previous epoch.
    /// @param poolId The pool ID to finalize.
    function finalizePool(bytes32 poolId) external;

    /// @notice Initialize storage owned by this contract.
    /// @dev This function should not be called directly.
    /// @dev The StakingProxy contract will call it in `attachStakingContract()`.
    function init() external;

    /// @notice Moves stake between statuses: 'undelegated' or 'delegated'.
    /// @dev Delegated stake can also be moved between pools.
    /// @dev This change comes into effect next epoch.
    /// @param from Status to move stake out of.
    /// @param to Status to move stake into.
    /// @param amount Amount of stake to move.
    function moveStake(
        IStructs.StakeInfo calldata from,
        IStructs.StakeInfo calldata to,
        uint256 amount
    ) external;

    /// @notice Credits the value of a pool's pop reward.
    /// @dev Only a known RigoBlock pop can call this method. See (MixinPopManager).
    /// @param poolAccount The address of the rigoblock pool account.
    /// @param popReward The pop reward.
    function creditPopReward(address poolAccount, uint256 popReward) external payable;

    /// @notice Removes an existing proof_of_performance address.
    /// @param addr Address of proof_of_performance contract to remove.
    function removePopAddress(address addr) external;

    /// @notice Set all configurable parameters at once.
    /// @param _epochDurationInSeconds Minimum seconds between epochs.
    /// @param _rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @param _minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @param _cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @param _cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    function setParams(
        uint256 _epochDurationInSeconds,
        uint32 _rewardDelegatedStakeWeight,
        uint256 _minimumPoolStake,
        uint32 _cobbDouglasAlphaNumerator,
        uint32 _cobbDouglasAlphaDenominator
    ) external;

    /// @notice Stake GRG tokens. Tokens are deposited into the GRG Vault.
    /// @dev Unstake to retrieve the GRG. Stake is in the 'Active' status.
    /// @param amount of GRG to stake.
    function stake(uint256 amount) external;

    /// @notice Unstake. Tokens are withdrawn from the GRG Vault and returned to the staker.
    /// @dev Stake must be in the 'undelegated' status in both the current and next epoch in order to be unstaked.
    /// @param amount of GRG to unstake.
    function unstake(uint256 amount) external;

    /// @notice Withdraws the caller's GRG rewards that have accumulated until the last epoch.
    /// @param poolId Unique id of pool.
    function withdrawDelegatorRewards(bytes32 poolId) external;

    /// @notice Computes the reward balance in GRG of a specific member of a pool.
    /// @param poolId Unique id of pool.
    /// @param member The member of the pool.
    /// @return reward Balance in GRG.
    function computeRewardBalanceOfDelegator(bytes32 poolId, address member) external view returns (uint256 reward);

    /// @notice Computes the reward balance in GRG of the operator of a pool.
    /// @param poolId Unique id of pool.
    /// @return reward Balance in GRG.
    function computeRewardBalanceOfOperator(bytes32 poolId) external view returns (uint256 reward);

    /// @notice Returns the earliest end time in seconds of this epoch.
    /// @dev The next epoch can begin once this time is reached.
    /// @dev Epoch period = [startTimeInSeconds..endTimeInSeconds)
    /// @return Time in seconds.
    function getCurrentEpochEarliestEndTimeInSeconds() external view returns (uint256);

    /// @notice Gets global stake for a given status.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Global stake for given status.
    function getGlobalStakeByStatus(IStructs.StakeStatus stakeStatus)
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @notice Gets an owner's stake balances by status.
    /// @param staker Owner of stake.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Owner's stake balances for given status.
    function getOwnerStakeByStatus(address staker, IStructs.StakeStatus stakeStatus)
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @notice Returns the total stake for a given staker.
    /// @param staker of stake.
    /// @return Total GRG staked by `staker`.
    function getTotalStake(address staker) external view returns (uint256);

    /// @dev Retrieves all configurable parameter values.
    /// @return _epochDurationInSeconds Minimum seconds between epochs.
    /// @return _rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @return _minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @return _cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @return _cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    function getParams()
        external
        view
        returns (
            uint256 _epochDurationInSeconds,
            uint32 _rewardDelegatedStakeWeight,
            uint256 _minimumPoolStake,
            uint32 _cobbDouglasAlphaNumerator,
            uint32 _cobbDouglasAlphaDenominator
        );

    /// @notice Returns stake delegated to pool by staker.
    /// @param staker of stake.
    /// @param poolId Unique Id of pool.
    /// @return balance Stake delegated to pool by staker.
    function getStakeDelegatedToPoolByOwner(address staker, bytes32 poolId)
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @notice Returns a staking pool
    /// @param poolId Unique id of pool.
    function getStakingPool(bytes32 poolId) external view returns (IStructs.Pool memory);

    /// @notice Get stats on a staking pool in this epoch.
    /// @param poolId Pool Id to query.
    /// @return PoolStats struct for pool id.
    function getStakingPoolStatsThisEpoch(bytes32 poolId) external view returns (IStructs.PoolStats memory);

    /// @notice Returns the total stake delegated to a specific staking pool, across all members.
    /// @param poolId Unique Id of pool.
    /// @return balance Total stake delegated to pool.
    function getTotalStakeDelegatedToPool(bytes32 poolId) external view returns (IStructs.StoredBalance memory balance);

    /// @notice An overridable way to access the deployed GRG contract.
    /// @dev Must be view to allow overrides to access state.
    /// @return The GRG contract instance.
    function getGrgContract() external view returns (RigoToken);

    /// @notice An overridable way to access the deployed grgVault.
    /// @dev Must be view to allow overrides to access state.
    /// @return The GRG vault contract.
    function getGrgVault() external view returns (GrgVault);

    /// @notice An overridable way to access the deployed rigoblock pool registry.
    /// @dev Must be view to allow overrides to access state.
    /// @return The pool registry contract.
    function getPoolRegistry() external view returns (PoolRegistry);
}