/*

    Copyright 2022 dYdX Trading Inc.

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title HedgiesRoles
 * @author dYdX
 *
 * @notice Defines roles used in the Hedgies contract. The hierarchy of roles and powers
 *  of each role are described below.
 *
 *  Roles:
 *
 *    DEFAULT_ADMIN_ROLE
 *      | -> May add or remove users from any of the below roles it manages.
 *      |
 *      +-- RESERVER_ROLE
 *      |    -> May reserve to any address as long as reserve supply has not been met.
 *      |
 *      +-- MINTER_ROLE
 *           -> May mint to any address as long as mint supply has not been met.
 */
contract HedgiesRoles is
  AccessControl
{
  bytes32 public constant RESERVER_ROLE = keccak256('RESERVER_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  constructor(
    address admin,
    address reserver,
    address minter
  ) {
    // Assign roles.
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(RESERVER_ROLE, reserver);
    _grantRole(MINTER_ROLE, minter);
  }
}