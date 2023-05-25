/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "GovernanceStorage.sol";

/*
  Holds the Proxy-specific state variables.
  This contract is inherited by the GovernanceStorage (and indirectly by MainStorage)
  to prevent collision hazard.
*/
contract ProxyStorage is GovernanceStorage {
    // NOLINTNEXTLINE: naming-convention uninitialized-state.
    mapping(address => bytes32) internal initializationHash_DEPRECATED;

    // The time after which we can switch to the implementation.
    // Hash(implementation, data, finalize) => time.
    mapping(bytes32 => uint256) internal enabledTime;

    // A central storage of the flags whether implementation has been initialized.
    // Note - it can be used flexibly enough to accommodate multiple levels of initialization
    // (i.e. using different key salting schemes for different initialization levels).
    mapping(bytes32 => bool) internal initialized;
}
