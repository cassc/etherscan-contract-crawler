//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibErrors.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title Withdrawal Credentials Storage
/// @notice Utility to manage the Withdrawal Credentials in storage
library WithdrawalCredentials {
    /// @notice Storage slot of the Withdrawal Credentials
    bytes32 internal constant WITHDRAWAL_CREDENTIALS_SLOT =
        bytes32(uint256(keccak256("river.state.withdrawalCredentials")) - 1);

    /// @notice Retrieve the Withdrawal Credentials
    /// @return The Withdrawal Credentials
    function get() internal view returns (bytes32) {
        return LibUnstructuredStorage.getStorageBytes32(WITHDRAWAL_CREDENTIALS_SLOT);
    }

    /// @notice Sets the Withdrawal Credentials
    /// @param _newValue New Withdrawal Credentials
    function set(bytes32 _newValue) internal {
        if (_newValue == bytes32(0)) {
            revert LibErrors.InvalidArgument();
        }
        LibUnstructuredStorage.setStorageBytes32(WITHDRAWAL_CREDENTIALS_SLOT, _newValue);
    }
}