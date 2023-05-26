// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

interface StakingPoolManagement {
    /// @notice sets a name for the pool using ENS service
    function setName(string memory name) external;

    /// @notice pauses new staking on the pool
    function pause() external;

    /// @notice unpauses new staking on the pool
    function unpause() external;

    /// @notice Event emmited when a pool is rename
    event StakingPoolRenamed(string name);
}