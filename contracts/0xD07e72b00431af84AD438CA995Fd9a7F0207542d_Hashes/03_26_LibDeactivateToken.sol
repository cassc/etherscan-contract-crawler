// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibDeactivateToken {
    struct DeactivateToken {
        uint256 proposalId;
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_DEACTIVATE_TOKEN_HASH = keccak256(abi.encodePacked(
    //        "DeactivateToken(",
    //        "uint256 proposalId",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_DEACTIVATE_TOKEN_SCHEMA_HASH =
        0xe6c775d77ef8ec84277aad8c3f9e3fa051e3ca07ea28a40e99a1fdf5b8cc0709;

    /// @dev Calculates Keccak-256 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return deactivateHash Keccak-256 EIP712 hash of the deactivation.
    function getDeactivateTokenHash(DeactivateToken memory _deactivate, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 deactivateHash)
    {
        deactivateHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashDeactivateToken(_deactivate));
        return deactivateHash;
    }

    /// @dev Calculates EIP712 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @return result EIP712 hash of the deactivate.
    function hashDeactivateToken(DeactivateToken memory _deactivate) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_DEACTIVATE_TOKEN_SCHEMA_HASH;

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