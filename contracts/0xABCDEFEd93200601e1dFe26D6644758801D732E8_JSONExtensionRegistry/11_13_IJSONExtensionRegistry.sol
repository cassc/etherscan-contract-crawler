// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @notice Zora Labs Interface for JSON Extension Registry v1
/// @dev Repo: github.com/ourzora/json-extension-registry
/// @author @iainnash / @mattlenz

interface IJSONExtensionRegistry {
    /// @notice Set address json extension file
    /// @dev Used to provide json extension information for rendering
    /// @param target target address to set metadata for
    /// @param uri uri to set metadata to
    function setJSONExtension(address target, string memory uri) external;

    /// @notice Getter for address json extension file
    /// @param target target contract for json extension
    /// @return address json extension for target
    function getJSONExtension(address target) external returns (string memory);

    /// @notice Get user's admin status externally
    /// @param target contract to check admin status for
    /// @param expectedAdmin user to check if they are listed as an a
    function getIsAdmin(address target, address expectedAdmin)
        external
        view
        returns (bool);

    /// @dev This contract call requires a contract admin that is not the caller
    error RequiresContractAdmin();

    /// @dev Emitted when a JSON Extension for an address is updated
    event JSONExtensionUpdated(
        address indexed target,
        address indexed updater,
        string newValue
    );
}