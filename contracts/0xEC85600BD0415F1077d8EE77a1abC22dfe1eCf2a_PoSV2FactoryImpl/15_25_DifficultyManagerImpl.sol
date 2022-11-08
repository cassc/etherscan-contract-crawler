// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Block Selector V2 Implementation

pragma solidity ^0.8.0;

import "./Difficulty.sol";
import "./abstracts/ADifficultyManager.sol";

contract DifficultyManagerImpl is ADifficultyManager {
    // lower bound for difficulty
    uint64 immutable minDifficulty;
    // 4 bytes constants
    // how fast the difficulty gets adjusted to reach the desired interval, number * 1000000
    uint32 immutable difficultyAdjustmentParameter;
    // desired block selection interval in ethereum blocks
    uint32 immutable targetInterval;
    // difficulty parameter defines how big the interval will be
    uint256 difficulty;

    constructor(
        uint128 _initialDifficulty,
        uint64 _minDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval
    ) {
        minDifficulty = _minDifficulty;
        difficulty = _initialDifficulty;
        difficultyAdjustmentParameter = _difficultyAdjustmentParameter;
        targetInterval = _targetInterval;
    }

    /// @notice Adjust difficulty based on new block production
    function adjustDifficulty(uint256 _blockPassed) internal override {
        difficulty = Difficulty.getNewDifficulty(
            minDifficulty,
            difficulty,
            difficultyAdjustmentParameter,
            targetInterval,
            _blockPassed
        );

        emit DifficultyUpdated(difficulty);
    }
}