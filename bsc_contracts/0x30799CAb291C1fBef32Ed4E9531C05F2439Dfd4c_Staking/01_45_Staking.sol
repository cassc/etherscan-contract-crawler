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

// solhint-disable-next-line
pragma solidity 0.8.17;

import "./interfaces/IStaking.sol";
import "./sys/MixinParams.sol";
import "./stake/MixinStake.sol";
import "./rewards/MixinPopRewards.sol";

contract Staking is IStaking, MixinParams, MixinStake, MixinPopRewards {
    /// @notice Setting owner to null address prevents admin direct calls to implementation.
    /// @dev Initializing immutable implementation address is used to allow delegatecalls only.
    /// @dev Direct calls to the  implementation contract are effectively locked.
    /// @param grgVault Address of the Grg vault.
    /// @param poolRegistry Address of the RigoBlock pool registry.
    /// @param rigoToken Address of the Grg token.
    constructor(
        address grgVault,
        address poolRegistry,
        address rigoToken
    ) Authorizable(address(0)) MixinDeploymentConstants(grgVault, poolRegistry, rigoToken) {}

    /// @notice Initialize storage owned by this contract.
    /// @dev This function should not be called directly.
    /// @dev The StakingProxy contract will call it in `attachStakingContract()`.
    function init() public override onlyAuthorized {
        // DANGER! When performing upgrades, take care to modify this logic
        // to prevent accidentally clearing prior state.
        _initMixinScheduler();
        _initMixinParams();
    }
}