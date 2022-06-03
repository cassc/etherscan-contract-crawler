//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @dev The interface to be inherited by Fractal module factories
interface IModuleFactory {
    error NotAuthorized();
    event VersionCreated(
        string semanticVersion,
        string frontendURI,
        address impl
    );
    struct VersionInfo {
        string semanticVersion;
        string frontendURI;
        address impl;
    }

    /// @dev add a new version to update module users
    /// @param _semanticVersion semantic version control
    /// @param _frontendURI IPFS hash of the static frontend
    /// @param _impl address of the impl
    function addVersion(
        string calldata _semanticVersion,
        string calldata _frontendURI,
        address _impl
    ) external;

    /// @dev Creates a module
    /// @param data The array of bytes used to create the module
    /// @return address[] Array of the created module addresses
    function create(bytes[] calldata data) external returns (address[] memory);

    /// @notice Returns whether a given interface ID is supported
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}