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

import "../../IRigoblockV3Pool.sol";

/// @notice Constants are copied in the bytecode and not assigned a storage slot, can safely be added to this contract.
/// @dev Inheriting from interface is required as we override public variables.
abstract contract MixinConstants is IRigoblockV3Pool {
    /// @inheritdoc IRigoblockV3PoolImmutable
    string public constant override VERSION = "HF 3.1.1";

    bytes32 internal constant _POOL_INIT_SLOT = 0xe48b9bb119adfc3bccddcc581484cc6725fe8d292ebfcec7d67b1f93138d8bd8;

    bytes32 internal constant _POOL_VARIABLES_SLOT = 0xe3ed9e7d534645c345f2d15f0c405f8de0227b60eb37bbeb25b26db462415dec;

    bytes32 internal constant _POOL_TOKENS_SLOT = 0xf46fb7ff9ff9a406787c810524417c818e45ab2f1997f38c2555c845d23bb9f6;

    bytes32 internal constant _POOL_ACCOUNTS_SLOT = 0xfd7547127f88410746fb7969b9adb4f9e9d8d2436aa2d2277b1103542deb7b8e;

    uint16 internal constant _FEE_BASE = 10000;

    uint16 internal constant _INITIAL_SPREAD = 500; // +-5%, in basis points

    uint16 internal constant _MAX_SPREAD = 1000; // +-10%, in basis points

    uint16 internal constant _MAX_TRANSACTION_FEE = 100; // maximum 1%

    // minimum order size 1/1000th of base to avoid dust clogging things up
    uint16 internal constant _MINIMUM_ORDER_DIVISOR = 1e3;

    uint16 internal constant _SPREAD_BASE = 10000;

    uint48 internal constant _MAX_LOCKUP = 30 days;

    uint48 internal constant _MIN_LOCKUP = 2;

    bytes4 internal constant _TRANSFER_FROM_SELECTOR =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    bytes4 internal constant _TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
}