//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for enacted propositions (propositions that already got executed)
library StorageEnactedPropositions {
    struct DiamondStorage {
        /// @dev Mapping of proposition's EIP712 hash to enacted flag
        mapping(bytes32 => bool) enactedPropositions;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.EnactedPropositions");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}