// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// @dev File types use uint instead of enum for upgradability
abstract contract HTMLRendererStorageV1 {
    /// @notice Javascript plain text file
    uint8 constant FILE_TYPE_JAVASCRIPT_PLAINTEXT = 0;

    /// @notice Javascript base64 encoded file
    uint8 constant FILE_TYPE_JAVASCRIPT_BASE64 = 1;

    /// @notice Javascript gzip encoded file
    uint8 constant FILE_TYPE_JAVASCRIPT_GZIP = 2;
}