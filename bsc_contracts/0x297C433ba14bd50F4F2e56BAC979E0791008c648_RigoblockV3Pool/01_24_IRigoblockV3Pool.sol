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

pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IERC20.sol";
import "./interfaces/pool/IRigoblockV3PoolActions.sol";
import "./interfaces/pool/IRigoblockV3PoolEvents.sol";
import "./interfaces/pool/IRigoblockV3PoolFallback.sol";
import "./interfaces/pool/IRigoblockV3PoolImmutable.sol";
import "./interfaces/pool/IRigoblockV3PoolInitializer.sol";
import "./interfaces/pool/IRigoblockV3PoolOwnerActions.sol";
import "./interfaces/pool/IRigoblockV3PoolState.sol";
import "./interfaces/pool/IStorageAccessible.sol";

/// @title Rigoblock V3 Pool Interface - Allows interaction with the pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3Pool is
    IERC20,
    IRigoblockV3PoolImmutable,
    IRigoblockV3PoolEvents,
    IRigoblockV3PoolFallback,
    IRigoblockV3PoolInitializer,
    IRigoblockV3PoolActions,
    IRigoblockV3PoolOwnerActions,
    IRigoblockV3PoolState,
    IStorageAccessible
{

}