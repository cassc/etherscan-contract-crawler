// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IVanillaV1Safelist01 {
    /// @notice Queries if given `token` address is safelisted.
    /// @param token The ERC-20 address
    /// @return true iff safelisted
    function isSafelisted(address token) external view returns (bool);

    /// @notice Queries the safelisted address of the next Vanilla version.
    /// @return The address of the next Vanilla version which implements IVanillaV1MigrationTarget02
    function nextVersion() external view returns (address);

    /// @notice Emitted when tokens are added to the safelist
    /// @param tokens The ERC-20 addresses that are added to the safelist
    event TokensAdded (address[] tokens);

    /// @notice Emitted when tokens are removed from the safelist
    /// @param tokens The ERC-20 addresses that are added to the safelist
    event TokensRemoved (address[] tokens);

    /// @notice Thrown when non-owner attempting to modify safelist state
    error UnauthorizedAccess ();
}