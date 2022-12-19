//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for the forming proposition
library StorageFormingProposition {
    struct DiamondStorage {
        /// @dev The hash of the forming proposition to be enacted
        bytes32 formingPropositionHash;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.FormingProposition");

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

    function _initStorage(bytes32 formingPropositionHash) internal {
        DiamondStorage storage ds = diamondStorage();

        require(
            formingPropositionHash != bytes32(0),
            "Storage: Invalid forming proposition hash"
        );

        ds.formingPropositionHash = formingPropositionHash;
    }
}