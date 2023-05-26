// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibDeactivateAuthority {
    struct DeactivateAuthority {
        bool support;
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_DEACTIVATE_AUTHORITY_HASH = keccak256(abi.encodePacked(
    //        "DeactivateAuthority(",
    //        "bool support",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_DEACTIVATE_AUTHORITY_SCHEMA_HASH =
        0x17dec47eaa269b80dfd59f06648e0096c5e96c83185c6a1be1c71cf853a79a40;

    /// @dev Calculates Keccak-256 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return deactivateHash Keccak-256 EIP712 hash of the deactivation.
    function getDeactivateAuthorityHash(DeactivateAuthority memory _deactivate, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 deactivateHash)
    {
        deactivateHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashDeactivateAuthority(_deactivate));
        return deactivateHash;
    }

    /// @dev Calculates EIP712 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @return result EIP712 hash of the deactivate.
    function hashDeactivateAuthority(DeactivateAuthority memory _deactivate) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_DEACTIVATE_AUTHORITY_SCHEMA_HASH;

        assembly {
            // Assert deactivate offset (this is an internal error that should never be triggered)
            if lt(_deactivate, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_deactivate, 32)

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