//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Allower Address Storage
/// @notice Utility to manage the Allower Address in storage
library AllowerAddress {
    /// @notice Storage slot of the Allower Address
    bytes32 internal constant ALLOWER_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.allowerAddress")) - 1);

    /// @notice Retrieve the Allower Address
    /// @return The Allower Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(ALLOWER_ADDRESS_SLOT);
    }

    /// @notice Sets the Allower Address
    /// @param _newValue New Allower Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(ALLOWER_ADDRESS_SLOT, _newValue);
    }
}