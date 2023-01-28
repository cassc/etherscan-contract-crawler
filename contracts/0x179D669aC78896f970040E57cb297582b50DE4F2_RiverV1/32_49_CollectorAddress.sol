//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Collector Address Storage
/// @notice Utility to manage the Collector Address in storage
library CollectorAddress {
    /// @notice Storage slot of the Collector Address
    bytes32 internal constant COLLECTOR_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.collectorAddress")) - 1);

    /// @notice Retrieve the Collector Address
    /// @return The Collector Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(COLLECTOR_ADDRESS_SLOT);
    }

    /// @notice Sets the Collector Address
    /// @param _newValue New Collector Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(COLLECTOR_ADDRESS_SLOT, _newValue);
    }
}