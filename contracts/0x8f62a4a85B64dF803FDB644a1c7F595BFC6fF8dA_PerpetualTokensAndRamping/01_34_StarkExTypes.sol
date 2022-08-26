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

// Structure representing a list of verifiers (validity/availability).
// A statement is valid only if all the verifiers in the list agree on it.
// Adding a verifier to the list is immediate - this is used for fast resolution of
// any soundness issues.
// Removing a verifier from the list is time-locked, to ensure that any user of the system
// not content with the announced removal has ample time to leave the system before it is
// removed.
struct ApprovalChainData {
    address[] verifiers;
    // Represents the time after which the verifier with the given address can be removed.
    // Removal of the verifier with address A is allowed only in the case the value
    // of verifierAllowedRemovalTime[A] != 0 and verifierAllowedRemovalTime[A] < (current time).
    mapping(address => uint256) verifierAllowedRemovalTime;
}