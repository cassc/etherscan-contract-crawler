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

import "../../utils/0xUtils/Authorizable.sol";
import "../interfaces/IGrgVault.sol";
import "../interfaces/IStorage.sol";
import "../interfaces/IStructs.sol";

// solhint-disable max-states-count, no-empty-blocks
abstract contract MixinStorage is IStorage, Authorizable {
    /// @inheritdoc IStorage
    address public override stakingContract;

    // mapping from StakeStatus to global stored balance
    // NOTE: only Status.DELEGATED is used to access this mapping, but this format
    // is used for extensibility
    mapping(uint8 => IStructs.StoredBalance) internal _globalStakeByStatus;

    // mapping from StakeStatus to address of staker to stored balance
    mapping(uint8 => mapping(address => IStructs.StoredBalance)) internal _ownerStakeByStatus;

    // Mapping from Owner to Pool Id to Amount Delegated
    mapping(address => mapping(bytes32 => IStructs.StoredBalance)) internal _delegatedStakeToPoolByOwner;

    // Mapping from Pool Id to Amount Delegated
    mapping(bytes32 => IStructs.StoredBalance) internal _delegatedStakeByPoolId;

    /// @inheritdoc IStorage
    mapping(address => bytes32) public override poolIdByRbPoolAccount;

    // mapping from Pool Id to Pool
    mapping(bytes32 => IStructs.Pool) internal _poolById;

    /// @inheritdoc IStorage
    mapping(bytes32 => uint256) public override rewardsByPoolId;

    /// @inheritdoc IStorage
    uint256 public override currentEpoch;

    /// @inheritdoc IStorage
    uint256 public override currentEpochStartTimeInSeconds;

    // mapping from Pool Id to Epoch to Reward Ratio
    mapping(bytes32 => mapping(uint256 => IStructs.Fraction)) internal _cumulativeRewardsByPool;

    // mapping from Pool Id to Epoch
    mapping(bytes32 => uint256) internal _cumulativeRewardsByPoolLastStored;

    /// @inheritdoc IStorage
    mapping(address => bool) public override validPops;

    /* Tweakable parameters */

    /// @inheritdoc IStorage
    uint256 public override epochDurationInSeconds;

    /// @inheritdoc IStorage
    uint32 public override rewardDelegatedStakeWeight;

    /// @inheritdoc IStorage
    uint256 public override minimumPoolStake;

    /// @inheritdoc IStorage
    uint32 public override cobbDouglasAlphaNumerator;

    /// @inheritdoc IStorage
    uint32 public override cobbDouglasAlphaDenominator;

    /* State for finalization */

    /// @inheritdoc IStorage
    mapping(bytes32 => mapping(uint256 => IStructs.PoolStats)) public override poolStatsByEpoch;

    /// @inheritdoc IStorage
    mapping(uint256 => IStructs.AggregatedStats) public aggregatedStatsByEpoch;

    /// @inheritdoc IStorage
    uint256 public grgReservedForPoolRewards;
}