//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Metadata URI Storage
/// @notice Utility to manage the Metadata in storage
library MetadataURI {
    /// @notice Storage slot of the Metadata URI
    bytes32 internal constant METADATA_URI_SLOT = bytes32(uint256(keccak256("river.state.metadataUri")) - 1);

    /// @notice Structure in storage
    struct Slot {
        /// @custom:attribute The metadata value
        string value;
    }

    /// @notice Retrieve the metadata URI
    /// @return The metadata URI string
    function get() internal view returns (string memory) {
        bytes32 slot = METADATA_URI_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Set the metadata URI value
    /// @param _newValue The new metadata URI value
    function set(string memory _newValue) internal {
        bytes32 slot = METADATA_URI_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value = _newValue;
    }
}