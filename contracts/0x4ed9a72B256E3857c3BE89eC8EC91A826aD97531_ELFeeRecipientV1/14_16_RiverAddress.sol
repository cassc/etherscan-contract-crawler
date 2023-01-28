//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title River Address Storage
/// @notice Utility to manage the River Address in storage
library RiverAddress {
    /// @notice Storage slot of the River Address
    bytes32 internal constant RIVER_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.riverAddress")) - 1);

    /// @notice Retrieve the River Address
    /// @return The River Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(RIVER_ADDRESS_SLOT);
    }

    /// @notice Sets the River Address
    /// @param _newValue New River Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(RIVER_ADDRESS_SLOT, _newValue);
    }
}