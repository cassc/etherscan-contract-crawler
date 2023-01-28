//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Reports Positions Storage
/// @notice Utility to manage the Reports Positions in storage
/// @dev Each bit in the stored uint256 value tells if the member at a given index has reported
library ReportsPositions {
    /// @notice Storage slot of the Reports Positions
    bytes32 internal constant REPORTS_POSITIONS_SLOT = bytes32(uint256(keccak256("river.state.reportsPositions")) - 1);

    /// @notice Retrieve the Reports Positions at index
    /// @param _idx The index to retrieve
    /// @return True if already reported
    function get(uint256 _idx) internal view returns (bool) {
        uint256 mask = 1 << _idx;
        return LibUnstructuredStorage.getStorageUint256(REPORTS_POSITIONS_SLOT) & mask == mask;
    }

    /// @notice Retrieve the raw Reports Positions from storage
    /// @return Raw Reports Positions
    function getRaw() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(REPORTS_POSITIONS_SLOT);
    }

    /// @notice Register an index as reported
    /// @param _idx The index to register
    function register(uint256 _idx) internal {
        uint256 mask = 1 << _idx;
        return LibUnstructuredStorage.setStorageUint256(
            REPORTS_POSITIONS_SLOT, LibUnstructuredStorage.getStorageUint256(REPORTS_POSITIONS_SLOT) | mask
        );
    }

    /// @notice Clears all the report positions in storage
    function clear() internal {
        return LibUnstructuredStorage.setStorageUint256(REPORTS_POSITIONS_SLOT, 0);
    }
}