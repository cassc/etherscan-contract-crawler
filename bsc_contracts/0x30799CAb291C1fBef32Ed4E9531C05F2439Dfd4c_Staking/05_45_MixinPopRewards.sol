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

import "../../utils/0xUtils/LibMath.sol";
import "../interfaces/IStructs.sol";
import "../sys/MixinFinalizer.sol";
import "../staking_pools/MixinStakingPool.sol";
import "./MixinPopManager.sol";

abstract contract MixinPopRewards is MixinPopManager, MixinStakingPool, MixinFinalizer {
    /// @dev Asserts that the call is coming from a valid pop.
    modifier onlyPop() {
        require(validPops[msg.sender], "STAKING_ONLY_CALLABLE_BY_POP_ERROR");
        _;
    }

    /// @inheritdoc IStaking
    function creditPopReward(address poolAccount, uint256 popReward) external payable override onlyPop {
        // Get the pool id of the maker address.
        bytes32 poolId = poolIdByRbPoolAccount[poolAccount];

        // Only attribute the pop reward to a pool if the pool account is
        // registered to a pool.
        require(poolId != _NIL_POOL_ID, "STAKING_NULL_POOL_ID_ERROR");

        uint256 poolStake = getTotalStakeDelegatedToPool(poolId).currentEpochBalance;
        // Ignore pools with dust stake.
        require(poolStake >= minimumPoolStake, "STAKING_STAKE_BELOW_MINIMUM_ERROR");

        // Look up the pool stats and aggregated stats for this epoch.
        uint256 currentEpoch_ = currentEpoch;
        IStructs.PoolStats storage poolStatsPtr = poolStatsByEpoch[poolId][currentEpoch_];
        IStructs.AggregatedStats storage aggregatedStatsPtr = aggregatedStatsByEpoch[currentEpoch_];

        // Perform some initialization if this is the pool's first protocol fee in this epoch.
        uint256 feesCollectedByPool = poolStatsPtr.feesCollected;
        if (feesCollectedByPool == 0) {
            // Compute member and total weighted stake.
            (uint256 membersStakeInPool, uint256 weightedStakeInPool) = _computeMembersAndWeightedStake(
                poolId,
                poolStake
            );
            poolStatsPtr.membersStake = membersStakeInPool;
            poolStatsPtr.weightedStake = weightedStakeInPool;

            // Increase the total weighted stake.
            aggregatedStatsPtr.totalWeightedStake += weightedStakeInPool;

            // Increase the number of pools to finalize.
            aggregatedStatsPtr.numPoolsToFinalize += 1;

            // Emit an event so keepers know what pools earned rewards this epoch.
            emit StakingPoolEarnedRewardsInEpoch(currentEpoch_, poolId);
        }

        if (popReward > feesCollectedByPool) {
            // Credit the fees to the pool.
            poolStatsPtr.feesCollected = popReward;

            // Increase the total fees collected this epoch.
            aggregatedStatsPtr.totalFeesCollected += popReward - feesCollectedByPool;
        }
    }

    /// @inheritdoc IStaking
    function getStakingPoolStatsThisEpoch(bytes32 poolId) external view override returns (IStructs.PoolStats memory) {
        return poolStatsByEpoch[poolId][currentEpoch];
    }

    /// @dev Computes the members and weighted stake for a pool at the current
    ///      epoch.
    /// @param poolId ID of the pool.
    /// @param totalStake Total (unweighted) stake in the pool.
    /// @return membersStake Non-operator stake in the pool.
    /// @return weightedStake Weighted stake of the pool.
    function _computeMembersAndWeightedStake(bytes32 poolId, uint256 totalStake)
        private
        view
        returns (uint256 membersStake, uint256 weightedStake)
    {
        uint256 operatorStake = getStakeDelegatedToPoolByOwner(_poolById[poolId].operator, poolId).currentEpochBalance;

        membersStake = totalStake - operatorStake;
        weightedStake =
            operatorStake +
            LibMath.getPartialAmountFloor(rewardDelegatedStakeWeight, _PPM_DENOMINATOR, membersStake);
        return (membersStake, weightedStake);
    }
}