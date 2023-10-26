//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Buffered Exceeding Eth storage
/// @notice Redeen Manager utility to manage the exceeding ETH with a redeem request
library BufferedExceedingEth {
    /// @notice Storage slot of the Redeem Buffered Eth
    bytes32 internal constant BUFFERED_EXCEEDING_ETH_SLOT =
        bytes32(uint256(keccak256("river.state.bufferedExceedingEth")) - 1);

    /// @notice Retrieve the Redeem Buffered Eth Value
    /// @return The Redeem Buffered Eth Value
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(BUFFERED_EXCEEDING_ETH_SLOT);
    }

    /// @notice Sets the Redeem Buffered Eth Value
    /// @param newValue The new value
    function set(uint256 newValue) internal {
        LibUnstructuredStorage.setStorageUint256(BUFFERED_EXCEEDING_ETH_SLOT, newValue);
    }
}