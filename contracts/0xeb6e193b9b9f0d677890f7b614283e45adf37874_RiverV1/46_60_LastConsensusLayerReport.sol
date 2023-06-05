//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../interfaces/components/IOracleManager.1.sol";

/// @title Last Consensus Layer Report Storage
/// @notice Utility to manage the Last Consensus Layer Report in storage
library LastConsensusLayerReport {
    /// @notice Storage slot of the Last Consensus Layer Report
    bytes32 internal constant LAST_CONSENSUS_LAYER_REPORT_SLOT =
        bytes32(uint256(keccak256("river.state.lastConsensusLayerReport")) - 1);

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The structure in storage
        IOracleManagerV1.StoredConsensusLayerReport value;
    }

    /// @notice Retrieve the Last Consensus Layer Report from storage
    /// @return The Last Consensus Layer Report
    function get() internal view returns (IOracleManagerV1.StoredConsensusLayerReport storage) {
        bytes32 slot = LAST_CONSENSUS_LAYER_REPORT_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Set the Last Consensus Layer Report value in storage
    /// @param _newValue The new value to set in storage
    function set(IOracleManagerV1.StoredConsensusLayerReport memory _newValue) internal {
        bytes32 slot = LAST_CONSENSUS_LAYER_REPORT_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value = _newValue;
    }
}