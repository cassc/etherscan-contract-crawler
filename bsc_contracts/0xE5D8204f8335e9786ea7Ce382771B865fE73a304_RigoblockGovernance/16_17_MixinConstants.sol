// SPDX-License-Identifier: Apache 2.0
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

pragma solidity >=0.8.0 <0.9.0;

import "../IRigoblockGovernance.sol";

/// @notice Constants are copied in the bytecode and not assigned a storage slot, can safely be added to this contract.
abstract contract MixinConstants is IRigoblockGovernance {
    /// @notice Contract version
    string internal constant VERSION = "1.0.0";

    /// @notice Maximum operations per proposal
    uint256 internal constant PROPOSAL_MAX_OPERATIONS = 10;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 internal constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the vote struct
    bytes32 internal constant VOTE_TYPEHASH = keccak256("Vote(uint256 proposalId,uint8 voteType)");

    bytes32 internal constant _GOVERNANCE_PARAMS_SLOT =
        0x0116feaee435dceaf94f40403a5223724fba6d709cb4ce4aea5becab48feb141;

    // implementation slot is same as declared in proxy
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 internal constant _NAME_SLOT = 0x553222b140782d4f4112160b374e6b1dc38e2837c7dcbf3ef473031724ed3bd4;

    bytes32 internal constant _PROPOSAL_SLOT = 0x52dbe777b6bf9bbaf43befe2c8e8af61027e6a0a8901def318a34b207514b5bc;

    bytes32 internal constant _PROPOSAL_COUNT_SLOT = 0x7d19d505a441201fb38442238c5f65c45e6231c74b35aed1c92ad842019eab9f;

    bytes32 internal constant _PROPOSED_ACTION_SLOT =
        0xe4ff3d203d0a873fb9ffd3a1bbd07943574a73114c5affe6aa0217c743adeb06;

    bytes32 internal constant _RECEIPT_SLOT = 0x5a7421539532aa5504e4251551519aa0a06f7c2a3b40bbade5235843e09ad5fe;
}