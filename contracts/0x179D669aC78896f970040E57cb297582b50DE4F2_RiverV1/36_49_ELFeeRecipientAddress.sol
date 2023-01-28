//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Execution Layer Fee Recipient Address Storage
/// @notice Utility to manage the Execution Layer Fee Recipient Address in storage
library ELFeeRecipientAddress {
    /// @notice Storage slot of the Execution Layer Fee Recipient Address
    bytes32 internal constant EL_FEE_RECIPIENT_ADDRESS =
        bytes32(uint256(keccak256("river.state.elFeeRecipientAddress")) - 1);

    /// @notice Retrieve the Execution Layer Fee Recipient Address
    /// @return The Execution Layer Fee Recipient Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(EL_FEE_RECIPIENT_ADDRESS);
    }

    /// @notice Sets the Execution Layer Fee Recipient Address
    /// @param _newValue New Execution Layer Fee Recipient Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(EL_FEE_RECIPIENT_ADDRESS, _newValue);
    }
}