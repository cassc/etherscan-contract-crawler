// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title MeToken factory interface
/// @author Carter Carlson (@cartercarlson)
interface IMeTokenFactory {
    /// @notice Create a meToken
    /// @param name        Name of meToken
    /// @param symbol      Symbol of meToken
    /// @param diamond     Address of diamond
    function create(
        string calldata name,
        string calldata symbol,
        address diamond
    ) external returns (address);
}