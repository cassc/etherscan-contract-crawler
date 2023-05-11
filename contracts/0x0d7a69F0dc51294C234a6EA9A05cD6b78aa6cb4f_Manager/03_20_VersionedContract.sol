/// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

/// @notice Versioned Contract Interface
/// @notice repo github.com/ourzora/nouns-protocol
abstract contract VersionedContract {
    function contractVersion() external pure returns (string memory) {
        return "1.0.0";
    }
}