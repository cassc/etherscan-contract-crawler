// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibVeto {
    struct Veto {
        uint128 proposalId; // Proposal ID
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_VETO_SCHEMA_HASH = keccak256(abi.encodePacked(
    //        "Veto(",
    //        "uint128 proposalId",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_VETO_SCHEMA_HASH =
        0x634b7f2828b36c241805efe02eca7354b65d9dd7345300a9c3fca91c0b028ad7;

    /// @dev Calculates Keccak-256 hash of the veto.
    /// @param _veto The veto structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return vetoHash Keccak-256 EIP712 hash of the veto.
    function getVetoHash(Veto memory _veto, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 vetoHash)
    {
        vetoHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashVeto(_veto));
        return vetoHash;
    }

    /// @dev Calculates EIP712 hash of the veto.
    /// @param _veto The veto structure.
    /// @return result EIP712 hash of the veto.
    function hashVeto(Veto memory _veto) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_VETO_SCHEMA_HASH;

        assembly {
            // Assert veto offset (this is an internal error that should never be triggered)
            if lt(_veto, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_veto, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 64)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}