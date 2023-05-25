// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "./interfaces/StakingPool.sol";
import "./StakingPoolData.sol";
import "./StakingPoolManagementImpl.sol";
import "./StakingPoolProducerImpl.sol";
import "./StakingPoolStakingImpl.sol";
import "./StakingPoolUserImpl.sol";
import "./StakingPoolWorkerImpl.sol";

contract StakingPoolImpl is
    StakingPool,
    StakingPoolData,
    StakingPoolManagementImpl,
    StakingPoolProducerImpl,
    StakingPoolStakingImpl,
    StakingPoolUserImpl,
    StakingPoolWorkerImpl
{
    constructor(
        address _ctsi,
        address _staking,
        address _workerManager,
        address _ens,
        uint256 _stakeLock
    )
        StakingPoolManagementImpl(_ens)
        StakingPoolProducerImpl(_ctsi)
        StakingPoolStakingImpl(_ctsi, _staking)
        StakingPoolUserImpl(_ctsi, _stakeLock)
        StakingPoolWorkerImpl(_workerManager)
    {}

    function initialize(address _fee, address _pos)
        external
        override
        initializer
    {
        __Pausable_init();
        __Ownable_init();
        __StakingPoolProducer_init(_fee, _pos);
        __StakingPoolStaking_init();
        __StakingPoolManagementImpl_init();
    }

    /// @notice updates the internal settings for important pieces of the Cartesi PoS system
    function update() external override onlyOwner {
        address _pos = factory.getPoS();
        __StakingPoolWorkerImpl_update(_pos);
    }

    function transferOwnership(address newOwner)
        public
        override(StakingPool, OwnableUpgradeable)
    {
        OwnableUpgradeable.transferOwnership(newOwner);
    }
}