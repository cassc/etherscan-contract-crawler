//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Redeem Demand storage
/// @notice Redeem Manager utility to store the current demand in LsETH
library RedeemDemand {
    /// @notice Storage slot of the Redeem Demand
    bytes32 internal constant REDEEM_DEMAND_SLOT = bytes32(uint256(keccak256("river.state.redeemDemand")) - 1);

    /// @notice Retrieve the Redeem Demand Value
    /// @return The Redeem Demand Value
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(REDEEM_DEMAND_SLOT);
    }

    /// @notice Sets the Redeem Demand Value
    /// @param newValue The new value
    function set(uint256 newValue) internal {
        LibUnstructuredStorage.setStorageUint256(REDEEM_DEMAND_SLOT, newValue);
    }
}