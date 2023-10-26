//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Redeem Manager Address Storage
/// @notice Utility to manage the Redeem Manager Address in storage
library RedeemManagerAddress {
    /// @notice Storage slot of the Redeem Manager Address
    bytes32 internal constant REDEEM_MANAGER_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.redeemManagerAddress")) - 1);

    /// @notice Retrieve the Redeem Manager Address
    /// @return The Redeem Manager Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(REDEEM_MANAGER_ADDRESS_SLOT);
    }

    /// @notice Sets the Redeem Manager Address
    /// @param _newValue New Redeem Manager Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(REDEEM_MANAGER_ADDRESS_SLOT, _newValue);
    }
}