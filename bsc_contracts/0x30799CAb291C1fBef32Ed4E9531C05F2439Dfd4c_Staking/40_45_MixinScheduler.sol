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

import "../immutable/MixinStorage.sol";
import "../interfaces/IStakingEvents.sol";
import "../interfaces/IStaking.sol";

abstract contract MixinScheduler is IStaking, IStakingEvents, MixinStorage {
    /// @inheritdoc IStaking
    function getCurrentEpochEarliestEndTimeInSeconds() public view override returns (uint256) {
        return currentEpochStartTimeInSeconds + epochDurationInSeconds;
    }

    /// @dev Initializes state owned by this mixin.
    ///      Fails if state was already initialized.
    function _initMixinScheduler() internal {
        // assert the current values before overwriting them.
        _assertSchedulerNotInitialized();

        // solhint-disable-next-line
        currentEpochStartTimeInSeconds = block.timestamp;
        currentEpoch = 1;
    }

    /// @dev Moves to the next epoch, given the current epoch period has ended.
    ///      Time intervals that are measured in epochs (like timeLocks) are also incremented, given
    ///      their periods have ended.
    function _goToNextEpoch() internal {
        // get current timestamp
        // solhint-disable-next-line not-rely-on-time
        uint256 currentBlockTimestamp = block.timestamp;

        // validate that we can increment the current epoch
        uint256 epochEndTime = getCurrentEpochEarliestEndTimeInSeconds();
        require(epochEndTime <= currentBlockTimestamp, "STAKING_TIMESTAMP_TOO_LOW_ERROR");

        // incremment epoch
        uint256 nextEpoch = currentEpoch + 1;
        currentEpoch = nextEpoch;
        currentEpochStartTimeInSeconds = currentBlockTimestamp;
    }

    /// @dev Assert scheduler state before initializing it.
    /// This must be updated for each migration.
    function _assertSchedulerNotInitialized() internal view {
        require(currentEpochStartTimeInSeconds == 0, "STAKING_SCHEDULER_ALREADY_INITIALIZED_ERROR");
    }
}