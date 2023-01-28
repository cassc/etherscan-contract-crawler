//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Expected Epoch Id Storage
/// @notice Utility to manage the Expected Epoch Id in storage
library ExpectedEpochId {
    /// @notice Storage slot of the Expected Epoch Id
    bytes32 internal constant EXPECTED_EPOCH_ID_SLOT = bytes32(uint256(keccak256("river.state.expectedEpochId")) - 1);

    /// @notice Retrieve the Expected Epoch Id
    /// @return The Expected Epoch Id
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(EXPECTED_EPOCH_ID_SLOT);
    }

    /// @notice Sets the Expected Epoch Id
    /// @param _newValue New Expected Epoch Id
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(EXPECTED_EPOCH_ID_SLOT, _newValue);
    }
}