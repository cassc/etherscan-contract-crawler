//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Last Epoch Id Storage
/// @notice Utility to manage the Last Epoch Id in storage
library LastEpochId {
    /// @notice Storage slot of the Last Epoch Id
    bytes32 internal constant LAST_EPOCH_ID_SLOT = bytes32(uint256(keccak256("river.state.lastEpochId")) - 1);

    /// @notice Retrieve the Last Epoch Id
    /// @return The Last Epoch Id
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(LAST_EPOCH_ID_SLOT);
    }

    /// @notice Sets the Last Epoch Id
    /// @param _newValue New Last Epoch Id
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(LAST_EPOCH_ID_SLOT, _newValue);
    }
}