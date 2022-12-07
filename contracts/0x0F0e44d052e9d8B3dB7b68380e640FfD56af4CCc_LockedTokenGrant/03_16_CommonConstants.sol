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
pragma solidity ^0.8.16;

// The locked tokens from the grant are released gradually over 4 years.
uint256 constant GRANT_LOCKUP_PERIOD = 1461 days; // 4 years.
uint256 constant DEFAULT_DURATION_GLOBAL_TIMELOCK = 365 days; // 1 years.
uint256 constant MAX_DURATION_GLOBAL_TIMELOCK = 731 days; // 2 years.
uint256 constant MIN_UNLOCK_DELAY = 7 days; // 1 week.
bytes32 constant LOCKED_GRANT_ADMIN_ROLE = keccak256("LOCKED_GRANT_ADMIN_ROLE");
bytes32 constant GLOBAL_TIMELOCK_ADMIN_ROLE = keccak256("GLOBAL_TIMELOCK_ADMIN_ROLE");

// This hash value is used as an ID for `DelegateRegistry`
// If the recipient delegates this ID to an agent address,
// that agent can trigger token release.
bytes32 constant LOCKED_TOKEN_RELEASE_AGENT = keccak256("STARKNET_LOCKED_TOKEN_RELEASE_AGENT");

// This hash value is used as an ID for `DelegateRegistry`
// If the recipient delegates this ID to an agent address,
// that agent can submit delegation related transactions.
bytes32 constant LOCKED_TOKEN_DELEGATION_AGENT = keccak256(
    "STARKNET_LOCKED_TOKEN_DELEGATION_AGENT"
);

// The start time of a LockedGrant (T), at the time of granting (t) must be in the time window
// (t - LOCKED_GRANT_MAX_START_PAST_OFFSET, t + LOCKED_GRANT_MAX_START_FUTURE_OFFSET)
// i.e. t - LOCKED_GRANT_MAX_START_PAST_OFFSET < T < t + LOCKED_GRANT_MAX_START_FUTURE_OFFSET.
uint256 constant LOCKED_GRANT_MAX_START_PAST_OFFSET = 182 days; // 6 months.
uint256 constant LOCKED_GRANT_MAX_START_FUTURE_OFFSET = 31 days; // 1 month.