//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title TotalValidatorExitsRequested Storage
/// @notice This value is the amount of performed exit requests, only increased when there is current exit demand
/// @notice Utility to manage the TotalValidatorExitsRequested in storage
library TotalValidatorExitsRequested {
    /// @notice Storage slot of the TotalValidatorExitsRequested
    bytes32 internal constant TOTAL_VALIDATOR_EXITS_REQUESTED_SLOT =
        bytes32(uint256(keccak256("river.state.totalValidatorExitsRequested")) - 1);

    /// @notice Retrieve the TotalValidatorExitsRequested
    /// @return The TotalValidatorExitsRequested
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(TOTAL_VALIDATOR_EXITS_REQUESTED_SLOT);
    }

    /// @notice Sets the TotalValidatorExitsRequested
    /// @param _newValue New TotalValidatorExitsRequested
    function set(uint256 _newValue) internal {
        return LibUnstructuredStorage.setStorageUint256(TOTAL_VALIDATOR_EXITS_REQUESTED_SLOT, _newValue);
    }
}