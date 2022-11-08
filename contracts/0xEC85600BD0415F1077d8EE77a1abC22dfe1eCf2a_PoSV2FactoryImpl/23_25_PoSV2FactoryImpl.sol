// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title PoS V2 Factory
/// @author Stephen Chen

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";

import "./PoSV2Factory.sol";
import "./PoSV2Impl.sol";

contract PoSV2FactoryImpl is Ownable, PoSV2Factory {
    /// @param _ctsiAddress address of token instance being used
    /// @param _stakingAddress address of StakingInterface
    /// @param _workerAuthAddress address of worker manager contract
    /// @param _difficultyAdjustmentParameter how quickly the difficulty gets updated
    /// @param _targetInterval how often we want to elect a block producer
    /// @param _rewardValue reward that reward manager contract pays
    /// @param _rewardDelay number of blocks confirmation before a reward can be claimed
    /// @param _version protocol version of PoS
    function createNewChain(
        address _ctsiAddress,
        address _stakingAddress,
        address _workerAuthAddress,
        // DifficultyManager constructor parameters
        uint128 _initialDifficulty,
        uint64 _minDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,
        // RewardManager constructor parameters
        uint256 _rewardValue,
        uint32 _rewardDelay,
        uint32 _version
    ) external override onlyOwner returns (address) {
        PoSV2Impl pos = new PoSV2Impl(
            _ctsiAddress,
            _stakingAddress,
            _workerAuthAddress,
            _initialDifficulty,
            _minDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval,
            _rewardValue,
            _rewardDelay,
            _version
        );

        emit NewChain(
            address(pos),
            _ctsiAddress,
            _stakingAddress,
            _workerAuthAddress,
            _initialDifficulty,
            _minDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval,
            _rewardValue,
            _rewardDelay,
            _version
        );

        pos.transferOwnership(msg.sender);

        return address(pos);
    }
}