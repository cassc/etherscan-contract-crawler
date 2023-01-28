//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Consensus Layer Spec Storage
/// @notice Utility to manage the Consensus Layer Spec in storage
library CLSpec {
    /// @notice Storage slot of the Consensus Layer Spec
    bytes32 internal constant CL_SPEC_SLOT = bytes32(uint256(keccak256("river.state.clSpec")) - 1);

    /// @notice The Consensus Layer Spec structure
    struct CLSpecStruct {
        /// @custom:attribute The count of epochs per frame, 225 means 24h
        uint64 epochsPerFrame;
        /// @custom:attribute The count of slots in an epoch (32 on mainnet)
        uint64 slotsPerEpoch;
        /// @custom:attribute The seconds in a slot (12 on mainnet)
        uint64 secondsPerSlot;
        /// @custom:attribute The block timestamp of the first consensus layer block
        uint64 genesisTime;
    }

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The structure in storage
        CLSpecStruct value;
    }

    /// @notice Retrieve the Consensus Layer Spec from storage
    /// @return The Consensus Layer Spec
    function get() internal view returns (CLSpecStruct memory) {
        bytes32 slot = CL_SPEC_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Set the Consensus Layer Spec value in storage
    /// @param _newCLSpec The new value to set in storage
    function set(CLSpecStruct memory _newCLSpec) internal {
        bytes32 slot = CL_SPEC_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value = _newCLSpec;
    }
}