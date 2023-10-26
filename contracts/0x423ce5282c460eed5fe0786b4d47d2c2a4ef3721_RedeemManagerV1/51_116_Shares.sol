//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Shares Count Storage
/// @notice Utility to manage the Shares Count in storage
library Shares {
    /// @notice Storage slot of the Shares Count
    bytes32 internal constant SHARES_SLOT = bytes32(uint256(keccak256("river.state.shares")) - 1);

    /// @notice Retrieve the Shares Count
    /// @return The Shares Count
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(SHARES_SLOT);
    }

    /// @notice Sets the Shares Count
    /// @param _newValue New Shares Count
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(SHARES_SLOT, _newValue);
    }
}