// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

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

import "./IRigoblockV3Pool.sol";
import "./core/immutable/MixinStorage.sol";
import "./core/state/MixinPoolState.sol";
import "./core/state/MixinStorageAccessible.sol";
import "./core/sys/MixinAbstract.sol";
import "./core/sys/MixinInitializer.sol";
import "./core/sys/MixinFallback.sol";

/// @title RigoblockV3Pool - A set of rules for Rigoblock pools.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract RigoblockV3Pool is
    IRigoblockV3Pool,
    MixinStorage,
    MixinFallback,
    MixinInitializer,
    MixinAbstract,
    MixinPoolState,
    MixinStorageAccessible
{
    /// @notice Owner is initialized to 0 to lock owner actions in this implementation.
    /// @notice Kyc provider set as will effectively lock direct mint/burn actions.
    constructor(address authority) MixinImmutables(authority) {
        // we lock implementation at deploy
        pool().owner = address(0);
        poolParams().kycProvider == address(1);
    }
}