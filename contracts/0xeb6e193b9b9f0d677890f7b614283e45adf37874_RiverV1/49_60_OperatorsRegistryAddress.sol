//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Operators Registry Address Storage
/// @notice Utility to manage the Operators Registry Address in storage
library OperatorsRegistryAddress {
    /// @notice Storage slot of the Operators Registry Address
    bytes32 internal constant OPERATORS_REGISTRY_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.operatorsRegistryAddress")) - 1);

    /// @notice Retrieve the Operators Registry Address
    /// @return The Operators Registry Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(OPERATORS_REGISTRY_ADDRESS_SLOT);
    }

    /// @notice Sets the Operators Registry Address
    /// @param _newValue New Operators Registry Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(OPERATORS_REGISTRY_ADDRESS_SLOT, _newValue);
    }
}