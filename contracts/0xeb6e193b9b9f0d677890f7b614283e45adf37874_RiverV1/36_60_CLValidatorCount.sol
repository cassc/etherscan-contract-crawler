//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Consensus Layer Validator Count Storage
/// @notice Utility to manage the Consensus Layer Validator Count in storage
/// @notice This state variable is deprecated and was kept due to migration logic needs
library CLValidatorCount {
    /// @notice Storage slot of the Consensus Layer Validator Count
    bytes32 internal constant CL_VALIDATOR_COUNT_SLOT = bytes32(uint256(keccak256("river.state.clValidatorCount")) - 1);

    /// @notice Retrieve the Consensus Layer Validator Count
    /// @return The Consensus Layer Validator Count
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(CL_VALIDATOR_COUNT_SLOT);
    }

    /// @notice Sets the Consensus Layer Validator Count
    /// @param _newValue New Consensus Layer Validator Count
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(CL_VALIDATOR_COUNT_SLOT, _newValue);
    }
}