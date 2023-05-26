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

library LibVoteCast {
    struct VoteCast {
        uint128 proposalId; // Proposal ID
        bool support; // Support
    }

    // Hash for the EIP712 OrderParams Schema
    //    bytes32 constant internal EIP712_VOTE_CAST_SCHEMA_HASH = keccak256(abi.encodePacked(
    //        "VoteCast(",
    //        "uint128 proposalId,",
    //        "bool support",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_VOTE_CAST_SCHEMA_HASH =
        0x4abb8ae9facc09d5584ac64f616551bfc03c3ac63e5c431132305bd9bc8f8246;

    /// @dev Calculates Keccak-256 hash of the vote cast.
    /// @param voteCast The vote cast structure.
    /// @return voteCastHash Keccak-256 EIP712 hash of the vote cast.
    function getVoteCastHash(VoteCast memory voteCast, bytes32 eip712ExchangeDomainHash)
        internal
        pure
        returns (bytes32 voteCastHash)
    {
        voteCastHash = LibEIP712.hashEIP712Message(eip712ExchangeDomainHash, hashVoteCast(voteCast));
        return voteCastHash;
    }

    /// @dev Calculates EIP712 hash of the vote cast.
    /// @param voteCast The vote cast structure.
    /// @return result EIP712 hash of the vote cast.
    function hashVoteCast(VoteCast memory voteCast) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_VOTE_CAST_SCHEMA_HASH;

        assembly {
            // Assert vote cast offset (this is an internal error that should never be triggered)
            if lt(voteCast, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(voteCast, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 96)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}