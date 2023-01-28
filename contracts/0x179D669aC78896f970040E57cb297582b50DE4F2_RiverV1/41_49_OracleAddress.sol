//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Oracle Address Storage
/// @notice Utility to manage the Oracle Address in storage
library OracleAddress {
    /// @notice Storage slot of the Oracle Address
    bytes32 internal constant ORACLE_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.oracleAddress")) - 1);

    /// @notice Retrieve the Oracle Address
    /// @return The Oracle Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(ORACLE_ADDRESS_SLOT);
    }

    /// @notice Sets the Oracle Address
    /// @param _newValue New Oracle Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(ORACLE_ADDRESS_SLOT, _newValue);
    }
}