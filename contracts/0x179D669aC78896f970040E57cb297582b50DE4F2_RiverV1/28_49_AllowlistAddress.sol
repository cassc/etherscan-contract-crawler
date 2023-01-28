//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Allowlist Address Storage
/// @notice Utility to manage the Allowlist Address in storage
library AllowlistAddress {
    /// @notice Storage slot of the Allowlist Address
    bytes32 internal constant ALLOWLIST_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.allowlistAddress")) - 1);

    /// @notice Retrieve the Allowlist Address
    /// @return The Allowlist Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(ALLOWLIST_ADDRESS_SLOT);
    }

    /// @notice Sets the Allowlist Address
    /// @param _newValue New Allowlist Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(ALLOWLIST_ADDRESS_SLOT, _newValue);
    }
}