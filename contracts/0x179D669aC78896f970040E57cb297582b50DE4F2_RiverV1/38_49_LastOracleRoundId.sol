//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Last Oracle Round Id Storage
/// @notice Utility to manage the Last Oracle Round Id in storage
library LastOracleRoundId {
    /// @notice Storage slot of the Last Oracle Round Id
    bytes32 internal constant LAST_ORACLE_ROUND_ID_SLOT =
        bytes32(uint256(keccak256("river.state.lastOracleRoundId")) - 1);

    /// @notice Retrieve the Last Oracle Round Id
    /// @return The Last Oracle Round Id
    function get() internal view returns (bytes32) {
        return LibUnstructuredStorage.getStorageBytes32(LAST_ORACLE_ROUND_ID_SLOT);
    }

    /// @notice Sets the Last Oracle Round Id
    /// @param _newValue New Last Oracle Round Id
    function set(bytes32 _newValue) internal {
        LibUnstructuredStorage.setStorageBytes32(LAST_ORACLE_ROUND_ID_SLOT, _newValue);
    }
}