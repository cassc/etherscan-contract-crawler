//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title Deposit Contract Address Storage
/// @notice Utility to manage the Deposit Contract Address in storage
library DepositContractAddress {
    /// @notice Storage slot of the Deposit Contract Address
    bytes32 internal constant DEPOSIT_CONTRACT_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.depositContractAddress")) - 1);

    /// @notice Retrieve the Deposit Contract Address
    /// @return The Deposit Contract Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(DEPOSIT_CONTRACT_ADDRESS_SLOT);
    }

    /// @notice Sets the Deposit Contract Address
    /// @param _newValue New Deposit Contract Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(DEPOSIT_CONTRACT_ADDRESS_SLOT, _newValue);
    }
}