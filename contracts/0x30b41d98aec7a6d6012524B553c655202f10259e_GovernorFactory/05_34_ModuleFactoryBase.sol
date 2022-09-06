//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IModuleFactory.sol";

/// @notice An abstract contract to be inherited by module contracts
abstract contract ModuleFactoryBase is
    IModuleFactory,
    ERC165,
    AccessControl,
    Initializable
{
    bytes32 public constant VERSION_ROLE = keccak256("VERSION_ROLE");
    VersionInfo[] public versionControl;

    /// @dev add a new version to update module users
    /// @param _semanticVersion semantic version control
    /// @param _frontendURI IPFS hash of the static frontend
    /// @param _impl address of the impl
    function addVersion(
        string calldata _semanticVersion,
        string calldata _frontendURI,
        address _impl
    ) external {
        if (!hasRole(VERSION_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        versionControl.push(VersionInfo(_semanticVersion, _frontendURI, _impl));
        emit VersionCreated(_semanticVersion, _frontendURI, _impl);
    }

    /// @dev Creates a module
    /// @param data The array of bytes used to create the module
    /// @return address[] Array of the created module addresses
    function create(bytes[] calldata data)
        external
        virtual
        returns (address[] memory);

    /// @notice Returns whether a given interface ID is supported
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IModuleFactory, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IModuleFactory).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Function for initializing the contract that can only be called once
    function __initFactoryBase() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VERSION_ROLE, msg.sender);
    }
}