//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Deposited Validator Count Storage
/// @notice Utility to manage the Deposited Validator Count in storage
library DepositedValidatorCount {
    /// @notice Storage slot of the Deposited Validator Count
    bytes32 internal constant DEPOSITED_VALIDATOR_COUNT_SLOT =
        bytes32(uint256(keccak256("river.state.depositedValidatorCount")) - 1);

    /// @notice Retrieve the Deposited Validator Count
    /// @return The Deposited Validator Count
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(DEPOSITED_VALIDATOR_COUNT_SLOT);
    }

    /// @notice Sets the Deposited Validator Count
    /// @param _newValue New Deposited Validator Count
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(DEPOSITED_VALIDATOR_COUNT_SLOT, _newValue);
    }
}