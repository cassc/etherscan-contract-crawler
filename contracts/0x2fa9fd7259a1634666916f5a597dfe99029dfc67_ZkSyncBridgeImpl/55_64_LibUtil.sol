// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LibBytes.sol";

/// @title LibUtil library
/// @notice library with helper functions to operate on bytes-data and addresses
/// @author socket dot tech
library LibUtil {
    /// @notice LibBytes library to handle operations on bytes
    using LibBytes for bytes;

    /// @notice function to extract revertMessage from bytes data
    /// @dev use the revertMessage and then further revert with a custom revert and message
    /// @param _res bytes data received from the transaction call
    function getRevertMsg(
        bytes memory _res
    ) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) {
            return "Transaction reverted silently";
        }
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }
}