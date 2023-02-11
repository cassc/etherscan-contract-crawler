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

interface IStorage {
    /// @notice Address of staking contract.
    /// @return stakingContract Address of the staking contract.
    function stakingContract() external view returns (address);

    /// @notice Mapping from RigoBlock pool subaccount to pool Id of rigoblock pool
    /// @dev 0 RigoBlock pool subaccount address.
    /// @return 0 The pool ID.
    function poolIdByRbPoolAccount(address) external view returns (bytes32);

    /// @notice mapping from pool ID to reward balance of members
    /// @dev 0 Pool ID.
    /// @return 0 The total reward balance of members in this pool.
    function rewardsByPoolId(bytes32) external view returns (uint256);

    /// @notice The current epoch.
    /// @return currentEpoch The number of the current epoch.
    function currentEpoch() external view returns (uint256);

    /// @notice The current epoch start time.
    /// @return currentEpochStartTimeInSeconds Timestamp of start time.
    function currentEpochStartTimeInSeconds() external view returns (uint256);

    /// @notice Registered RigoBlock Proof_of_Performance contracts, capable of paying protocol fees.
    /// @dev 0 The address to check.
    /// @return 0 Whether the address is a registered proof_of_performance.
    function validPops(address popAddress) external view returns (bool);

    /// @notice Minimum seconds between epochs.
    /// @return epochDurationInSeconds Number of seconds.
    function epochDurationInSeconds() external view returns (uint256);

    // @notice How much delegated stake is weighted vs operator stake, in ppm.
    /// @return rewardDelegatedStakeWeight Number in units of a million.
    function rewardDelegatedStakeWeight() external view returns (uint32);

    /// @notice Minimum amount of stake required in a pool to collect rewards.
    /// @return minimumPoolStake Minimum amount required.
    function minimumPoolStake() external view returns (uint256);

    /// @notice Numerator for cobb douglas alpha factor.
    /// @return cobbDouglasAlphaNumerator Number of the numerator.
    function cobbDouglasAlphaNumerator() external view returns (uint32);

    /// @notice Denominator for cobb douglas alpha factor.
    /// @return cobbDouglasAlphaDenominator Number of the denominator.
    function cobbDouglasAlphaDenominator() external view returns (uint32);

    /// @notice Stats for each pool that generated fees with sufficient stake to earn rewards.
    /// @dev See `_minimumPoolStake` in `MixinParams`.
    /// @param key Pool ID.
    /// @param epoch Epoch number.
    /// @return feesCollected Amount of fees collected in epoch.
    /// @return weightedStake Weighted stake per million.
    /// @return membersStake Members stake per million.
    function poolStatsByEpoch(bytes32 key, uint256 epoch)
        external
        view
        returns (
            uint256 feesCollected,
            uint256 weightedStake,
            uint256 membersStake
        );

    /// @notice Aggregated stats across all pools that generated fees with sufficient stake to earn rewards.
    /// @dev See `_minimumPoolStake` in MixinParams.
    /// @param epoch Epoch number.
    /// @return rewardsAvailable Rewards (GRG) available to the epoch being finalized (the previous epoch).
    /// @return numPoolsToFinalize The number of pools that have yet to be finalized through `finalizePools()`.
    /// @return totalFeesCollected The total fees collected for the epoch being finalized.
    /// @return totalWeightedStake The total fees collected for the epoch being finalized.
    /// @return totalRewardsFinalized Amount of rewards that have been paid during finalization.
    function aggregatedStatsByEpoch(uint256 epoch)
        external
        view
        returns (
            uint256 rewardsAvailable,
            uint256 numPoolsToFinalize,
            uint256 totalFeesCollected,
            uint256 totalWeightedStake,
            uint256 totalRewardsFinalized
        );

    /// @notice The GRG balance of this contract that is reserved for pool reward payouts.
    /// @return grgReservedForPoolRewards Number of tokens reserved for rewards.
    function grgReservedForPoolRewards() external view returns (uint256);
}