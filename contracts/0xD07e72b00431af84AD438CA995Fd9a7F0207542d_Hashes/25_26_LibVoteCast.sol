// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibVoteCast {
    struct VoteCast {
        uint128 proposalId; // Proposal ID
        bool support; // Support
        bool deactivate; // Deactivation preference
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_VOTE_CAST_SCHEMA_HASH = keccak256(abi.encodePacked(
    //        "VoteCast(",
    //        "uint128 proposalId,",
    //        "bool support,",
    //        "bool deactivate",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_VOTE_CAST_SCHEMA_HASH =
        0xe2e736baec1b33e622ec76a499ffd32b809860cc499f4d543162d229e795be74;

    /// @dev Calculates Keccak-256 hash of the vote cast.
    /// @param _voteCast The vote cast structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return voteCastHash Keccak-256 EIP712 hash of the vote cast.
    function getVoteCastHash(VoteCast memory _voteCast, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 voteCastHash)
    {
        voteCastHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashVoteCast(_voteCast));
        return voteCastHash;
    }

    /// @dev Calculates EIP712 hash of the vote cast.
    /// @param _voteCast The vote cast structure.
    /// @return result EIP712 hash of the vote cast.
    function hashVoteCast(VoteCast memory _voteCast) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_VOTE_CAST_SCHEMA_HASH;

        assembly {
            // Assert vote cast offset (this is an internal error that should never be triggered)
            if lt(_voteCast, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_voteCast, 32)

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