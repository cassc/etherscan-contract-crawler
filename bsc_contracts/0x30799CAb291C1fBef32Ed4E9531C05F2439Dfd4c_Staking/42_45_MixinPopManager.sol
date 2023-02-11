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

import "../interfaces/IStakingEvents.sol";
import "../interfaces/IStaking.sol";
import "../immutable/MixinStorage.sol";

abstract contract MixinPopManager is IStaking, IStakingEvents, MixinStorage {
    /// @inheritdoc IStaking
    function addPopAddress(address addr) external override onlyAuthorized {
        require(!validPops[addr], "STAKING_POP_ALREADY_REGISTERED_ERROR");
        validPops[addr] = true;
        emit PopAdded(addr);
    }

    /// @inheritdoc IStaking
    function removePopAddress(address addr) external override onlyAuthorized {
        require(validPops[addr], "STAKING_POP_NOT_REGISTERED_ERROR");
        validPops[addr] = false;
        emit PopRemoved(addr);
    }
}