//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Balance For Coverage Value Storage
/// @notice Utility to manage the Balance For Coverrage value in storage
library BalanceForCoverage {
    /// @notice Storage slot of the Balance For Coverage Address
    bytes32 internal constant BALANCE_FOR_COVERAGE_SLOT =
        bytes32(uint256(keccak256("river.state.balanceForCoverage")) - 1);

    /// @notice Get the Balance for Coverage value
    /// @return The balance for coverage value
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(BALANCE_FOR_COVERAGE_SLOT);
    }

    /// @notice Sets the Balance for Coverage value
    /// @param _newValue New Balance for Coverage value
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(BALANCE_FOR_COVERAGE_SLOT, _newValue);
    }
}