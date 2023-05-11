/// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

/// @title IVersionedContract
/// @notice repo github.com/ourzora/nouns-protocol
interface IVersionedContract {
    function contractVersion() external pure returns (string memory);
}