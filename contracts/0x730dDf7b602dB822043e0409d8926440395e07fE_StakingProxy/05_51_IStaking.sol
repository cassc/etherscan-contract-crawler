/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

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

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../rigoToken/RigoToken/RigoTokenFace.sol";
import "../../protocol/DragoRegistry/IDragoRegistry.sol";
import "./IStructs.sol";
import "./IGrgVault.sol";


interface IStaking {

    /// @dev Adds a new proof_of_performance address.
    /// @param addr Address of proof_of_performance contract to add.
    function addPopAddress(address addr)
        external;
        
    /// @dev Create a new staking pool. The sender will be the staking pal of this pool.
    /// Note that a staking pal must be payable.
    /// @param rigoblockPoolAddress Adds rigoblock pool to the created staking pool for convenience if non-null.
    /// @return poolId The unique pool id generated for this pool.
    function createStakingPool(address rigoblockPoolAddress)
        external
        returns (bytes32 poolId);
    
    /// @dev Allows the operator to update the staking pal address.
    /// @param poolId Unique id of pool.
    /// @param newStakingPalAddress Address of the new staking pal.
    function setStakingPalAddress(bytes32 poolId, address newStakingPalAddress)
        external;

    /// @dev Decreases the operator share for the given pool (i.e. increases pool rewards for members).
    /// @param poolId Unique Id of pool.
    /// @param newOperatorShare The newly decreased percentage of any rewards owned by the operator.
    function decreaseStakingPoolOperatorShare(bytes32 poolId, uint32 newOperatorShare)
        external;

    /// @dev Begins a new epoch, preparing the prior one for finalization.
    ///      Throws if not enough time has passed between epochs or if the
    ///      previous epoch was not fully finalized.
    /// @return numPoolsToFinalize The number of unfinalized pools.
    function endEpoch()
        external
        returns (uint256);

    /// @dev Instantly finalizes a single pool that earned rewards in the previous
    ///      epoch, crediting it rewards for members and withdrawing operator's
    ///      rewards as WETH. This can be called by internal functions that need
    ///      to finalize a pool immediately. Does nothing if the pool is already
    ///      finalized or did not earn rewards in the previous epoch.
    /// @param poolId The pool ID to finalize.
    function finalizePool(bytes32 poolId)
        external;

    /// @dev Initialize storage owned by this contract.
    ///      This function should not be called directly.
    ///      The StakingProxy contract will call it in `attachStakingContract()`.
    function init()
        external;

    /// @dev Allows caller to join a staking pool as a rigoblock pool id subaccount.
    /// @param stakingPoolId Unique id of staking pool.
    /// @param rigoblockPoolAccount Address of subaccount to be added to staking pool.
    function joinStakingPoolAsRbPoolAccount(
        bytes32 stakingPoolId,
        address rigoblockPoolAccount)
        external;

    /// @dev Moves stake between statuses: 'undelegated' or 'delegated'.
    ///      Delegated stake can also be moved between pools.
    ///      This change comes into effect next epoch.
    /// @param from status to move stake out of.
    /// @param to status to move stake into.
    /// @param amount of stake to move.
    function moveStake(
        IStructs.StakeInfo calldata from,
        IStructs.StakeInfo calldata to,
        uint256 amount
    )
        external;
        
    /// @dev Credits the value of a pool's pop reward.
    ///      Only a known RigoBlock pop can call this method. See
    ///      (MixinPopManager).
    /// @param poolAccount The address of the rigoblock pool account.
    /// @param popReward The pop reward.
    function creditPopReward(
        address poolAccount,
        uint256 popReward
    )
        external
        payable;

    /// @dev Removes an existing proof_of_performance address.
    /// @param addr Address of proof_of_performance contract to remove.
    function removePopAddress(address addr)
        external;

    /// @dev Set all configurable parameters at once.
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
    )
        external;

    /// @dev Stake GRG tokens. Tokens are deposited into the GRG Vault.
    ///      Unstake to retrieve the GRG. Stake is in the 'Active' status.
    /// @param amount of GRG to stake.
    function stake(uint256 amount)
        external;

    /// @dev Unstake. Tokens are withdrawn from the GRG Vault and returned to
    ///      the staker. Stake must be in the 'undelegated' status in both the
    ///      current and next epoch in order to be unstaked.
    /// @param amount of GRG to unstake.
    function unstake(uint256 amount)
        external;

    /// @dev Withdraws the caller's WETH rewards that have accumulated
    ///      until the last epoch.
    /// @param poolId Unique id of pool.
    function withdrawDelegatorRewards(bytes32 poolId)
        external;

    /// @dev Computes the reward balance in ETH of a specific member of a pool.
    /// @param poolId Unique id of pool.
    /// @param member The member of the pool.
    /// @return reward Balance in ETH.
    function computeRewardBalanceOfDelegator(bytes32 poolId, address member)
        external
        view
        returns (uint256 reward);

    /// @dev Computes the reward balance in ETH of the operator of a pool.
    /// @param poolId Unique id of pool.
    /// @return reward Balance in ETH.
    function computeRewardBalanceOfOperator(bytes32 poolId)
        external
        view
        returns (uint256 reward);

    /// @dev Returns the earliest end time in seconds of this epoch.
    ///      The next epoch can begin once this time is reached.
    ///      Epoch period = [startTimeInSeconds..endTimeInSeconds)
    /// @return Time in seconds.
    function getCurrentEpochEarliestEndTimeInSeconds()
        external
        view
        returns (uint256);

    /// @dev Gets global stake for a given status.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Global stake for given status.
    function getGlobalStakeByStatus(IStructs.StakeStatus stakeStatus)
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @dev Gets an owner's stake balances by status.
    /// @param staker Owner of stake.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Owner's stake balances for given status.
    function getOwnerStakeByStatus(
        address staker,
        IStructs.StakeStatus stakeStatus
    )
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @dev Returns the total stake for a given staker.
    /// @param staker of stake.
    /// @return Total GRG staked by `staker`.
    function getTotalStake(address staker)
        external
        view
        returns (uint256);

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

    /// @param staker of stake.
    /// @param poolId Unique Id of pool.
    /// @return balance Stake delegated to pool by staker.
    function getStakeDelegatedToPoolByOwner(address staker, bytes32 poolId)
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @dev Returns a staking pool
    /// @param poolId Unique id of pool.
    function getStakingPool(bytes32 poolId)
        external
        view
        returns (IStructs.Pool memory);

    /// @dev Get stats on a staking pool in this epoch.
    /// @param poolId Pool Id to query.
    /// @return PoolStats struct for pool id.
    function getStakingPoolStatsThisEpoch(bytes32 poolId)
        external
        view
        returns (IStructs.PoolStats memory);

    /// @dev Returns the total stake delegated to a specific staking pool,
    ///      across all members.
    /// @param poolId Unique Id of pool.
    /// @return balance Total stake delegated to pool.
    function getTotalStakeDelegatedToPool(bytes32 poolId)
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @dev An overridable way to access the deployed GRG contract.
    ///      Must be view to allow overrides to access state.
    /// @return grgContract The GRG contract instance.
    function getGrgContract()
        external
        view
        returns (RigoTokenFace grgContract);

    /// @dev An overridable way to access the deployed dragoRegistry.
    ///      Must be view to allow overrides to access state.
    /// @return dragoRegistry The dragoRegistry contract.
    function getDragoRegistry()
        external
        view
        returns (IDragoRegistry dragoRegistry);

    /// @dev An overridable way to access the deployed grgVault.
    ///      Must be view to allow overrides to access state.
    /// @return grgVault The grgVault contract.
    function getGrgVault()
        external
        view
        returns (IGrgVault grgVault);
}