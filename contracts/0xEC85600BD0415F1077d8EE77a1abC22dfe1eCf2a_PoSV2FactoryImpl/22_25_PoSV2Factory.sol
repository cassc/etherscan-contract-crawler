// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.8.0;

interface PoSV2Factory {
    /// @notice Creates a new chain pos contract
    /// emits NewChain with the parameters of the new chain
    /// @return new chain address
    function createNewChain(
        address _ctsiAddress,
        address _stakingAddress,
        address _workerAuthAddress,
        uint128 _initialDifficulty,
        uint64 _minDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,
        uint256 _rewardValue,
        uint32 _rewardDelay,
        uint32 _version
    ) external returns (address);

    /// @notice Event emmited when a new chain is created
    /// @param pos address of the new chain
    event NewChain(
        address indexed pos,
        address ctsiAddress,
        address stakingAddress,
        address workerAuthAddress,
        uint128 initialDifficulty,
        uint64 minDifficulty,
        uint32 difficultyAdjustmentParameter,
        uint32 targetInterval,
        uint256 rewardValue,
        uint32 rewardDelay,
        uint32 version
    );
}