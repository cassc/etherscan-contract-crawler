//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Coverage Fund Address Storage
/// @notice Utility to manage the Coverage Fund Address in storage
library CoverageFundAddress {
    /// @notice Storage slot of the Coverage Fund Address
    bytes32 internal constant COVERAGE_FUND_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.coverageFundAddress")) - 1);

    /// @notice Retrieve the Coverage Fund Address
    /// @return The Coverage Fund Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(COVERAGE_FUND_ADDRESS_SLOT);
    }

    /// @notice Sets the Coverage Fund Address
    /// @param _newValue New Coverage Fund Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(COVERAGE_FUND_ADDRESS_SLOT, _newValue);
    }
}