//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Quorum Storage
/// @notice Utility to manage the Quorum in storage
library Quorum {
    /// @notice Storage slot of the Quorum
    bytes32 internal constant QUORUM_SLOT = bytes32(uint256(keccak256("river.state.quorum")) - 1);

    /// @notice Retrieve the Quorum
    /// @return The Quorum
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(QUORUM_SLOT);
    }

    /// @notice Sets the Quorum
    /// @param _newValue New Quorum
    function set(uint256 _newValue) internal {
        return LibUnstructuredStorage.setStorageUint256(QUORUM_SLOT, _newValue);
    }
}