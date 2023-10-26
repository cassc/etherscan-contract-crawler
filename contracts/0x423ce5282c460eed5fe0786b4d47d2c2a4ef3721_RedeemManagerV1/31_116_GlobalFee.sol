//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title Global Fee Storage
/// @notice Utility to manage the Global Fee in storage
library GlobalFee {
    /// @notice Storage slot of the Global Fee
    bytes32 internal constant GLOBAL_FEE_SLOT = bytes32(uint256(keccak256("river.state.globalFee")) - 1);

    /// @notice Retrieve the Global Fee
    /// @return The Global Fee
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(GLOBAL_FEE_SLOT);
    }

    /// @notice Sets the Global Fee
    /// @param _newValue New Global Fee
    function set(uint256 _newValue) internal {
        LibSanitize._validFee(_newValue);
        LibUnstructuredStorage.setStorageUint256(GLOBAL_FEE_SLOT, _newValue);
    }
}