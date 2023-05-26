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

import "@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

import "./interfaces/StakingPoolManagement.sol";
import "./interfaces/StakingPoolFactory.sol";
import "./StakingPoolData.sol";

contract StakingPoolManagementImpl is StakingPoolManagement, StakingPoolData {
    bytes32 private constant ADDR_REVERSE_NODE =
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    ENS public immutable ens;
    StakingPoolFactory public factory;

    // all immutable variables can stay at the constructor
    constructor(address _ens) initializer {
        require(_ens != address(0), "parameter can not be zero address");
        ens = ENS(_ens);

        // make sure reference code is pause so no one stake to it
        _pause();
    }

    function __StakingPoolManagementImpl_init() internal {
        factory = StakingPoolFactory(msg.sender);
    }

    /// @notice sets a name for the pool using ENS service
    function setName(string memory name) external override onlyOwner {
        ReverseRegistrar ensReverseRegistrar = ReverseRegistrar(
            ens.owner(ADDR_REVERSE_NODE)
        );

        // call the ENS reverse registrar resolving pool address to name
        ensReverseRegistrar.setName(name);

        // emit event, for subgraph processing
        emit StakingPoolRenamed(name);
    }

    /// @notice pauses new staking on the pool
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice unpauses new staking on the pool
    function unpause() external override onlyOwner {
        _unpause();
    }
}