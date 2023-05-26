// SPDX-License-Identifier: MIT
/*

  Copyright 2018 ZeroEx Intl.

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

pragma solidity 0.6.12;

import { LibEIP712 } from "./LibEIP712.sol";

library LibDelegation {
    struct Delegation {
        address delegatee; // Delegatee
        uint256 nonce; // Nonce
        uint256 expiry; // Expiry
    }

    // Hash for the EIP712 OrderParams Schema
    //    bytes32 constant internal EIP712_DELEGATION_SCHEMA_HASH = keccak256(abi.encodePacked(
    //        "Delegation(",
    //        "address delegatee,",
    //        "uint256 nonce,",
    //        "uint256 expiry",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_DELEGATION_SCHEMA_HASH =
        0xe48329057bfd03d55e49b547132e39cffd9c1820ad7b9d4c5307691425d15adf;

    /// @dev Calculates Keccak-256 hash of the delegation.
    /// @param delegation The delegation structure.
    /// @return delegationHash Keccak-256 EIP712 hash of the delegation.
    function getDelegationHash(Delegation memory delegation, bytes32 eip712ExchangeDomainHash)
        internal
        pure
        returns (bytes32 delegationHash)
    {
        delegationHash = LibEIP712.hashEIP712Message(eip712ExchangeDomainHash, hashDelegation(delegation));
        return delegationHash;
    }

    /// @dev Calculates EIP712 hash of the delegation.
    /// @param delegation The delegation structure.
    /// @return result EIP712 hash of the delegation.
    function hashDelegation(Delegation memory delegation) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_DELEGATION_SCHEMA_HASH;

        assembly {
            // Assert delegation offset (this is an internal error that should never be triggered)
            if lt(delegation, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(delegation, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 128)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}