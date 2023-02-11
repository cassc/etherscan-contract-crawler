// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2023 Rigo Intl.

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

pragma solidity 0.8.17;

import "./mixins/MixinInitializer.sol";
import "./mixins/MixinState.sol";
import "./mixins/MixinStorage.sol";
import "./mixins/MixinUpgrade.sol";
import "./mixins/MixinVoting.sol";
import "./IRigoblockGovernance.sol";

contract RigoblockGovernance is
    IRigoblockGovernance,
    MixinStorage,
    MixinInitializer,
    MixinUpgrade,
    MixinVoting,
    MixinState
{
    /// @notice Constructor has no inputs to guarantee same deterministic address across chains.
    /// @dev Setting high proposal threshold locks propose action, which also lock vote actions.
    constructor() MixinImmutables() MixinStorage() {
        _paramsWrapper().governanceParameters = GovernanceParameters({
            strategy: address(0),
            proposalThreshold: type(uint256).max,
            quorumThreshold: 0,
            timeType: TimeType.Timestamp
        });
    }
}