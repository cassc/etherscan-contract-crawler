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

import "./StakingPoolManagement.sol";
import "./StakingPoolProducer.sol";
import "./StakingPoolStaking.sol";
import "./StakingPoolUser.sol";
import "./StakingPoolWorker.sol";

/// @title Staking Pool interface
/// @author Danilo Tuler
/// @notice This interface aggregates all facets of a staking pool.
/// It is broken down into the following sub-interfaces:
/// - StakingPoolManagement: management operations on the pool, called by the owner
/// - StakingPoolProducer: operations related to block production
/// - StakingPoolStaking: interaction between the pool and the staking contract
/// - StakingPoolUser: interaction between the pool users and the pool
/// - StakingPoolWorker: interaction between the pool and the worker node
interface StakingPool is
    StakingPoolManagement,
    StakingPoolProducer,
    StakingPoolStaking,
    StakingPoolUser,
    StakingPoolWorker
{
    /// @notice initialize pool (from reference)
    function initialize(address fee, address _pos) external;

    /// @notice Transfer ownership of pool to its deployer
    function transferOwnership(address newOwner) external;

    /// @notice updates the internal settings for important pieces of the Cartesi PoS system
    function update() external;
}