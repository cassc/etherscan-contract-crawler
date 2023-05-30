// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/SelfMulticall.sol";
import "./RoleDeriver.sol";
import "./interfaces/IAccessControlRegistryAdminned.sol";
import "./interfaces/IAccessControlRegistry.sol";

/// @title Contract to be inherited by contracts whose adminship functionality
/// will be implemented using AccessControlRegistry
contract AccessControlRegistryAdminned is
    SelfMulticall,
    RoleDeriver,
    IAccessControlRegistryAdminned
{
    /// @notice AccessControlRegistry contract address
    address public immutable override accessControlRegistry;

    /// @notice Admin role description
    string public override adminRoleDescription;

    bytes32 internal immutable adminRoleDescriptionHash;

    /// @dev Contracts deployed with the same admin role descriptions will have
    /// the same roles, meaning that granting an account a role will authorize
    /// it in multiple contracts. Unless you want your deployed contract to
    /// share the role configuration of another contract, use a unique admin
    /// role description.
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription
    ) {
        require(_accessControlRegistry != address(0), "ACR address zero");
        require(
            bytes(_adminRoleDescription).length > 0,
            "Admin role description empty"
        );
        accessControlRegistry = _accessControlRegistry;
        adminRoleDescription = _adminRoleDescription;
        adminRoleDescriptionHash = keccak256(
            abi.encodePacked(_adminRoleDescription)
        );
    }

    /// @notice Derives the admin role for the specific manager address
    /// @param manager Manager address
    /// @return adminRole Admin role
    function _deriveAdminRole(
        address manager
    ) internal view returns (bytes32 adminRole) {
        adminRole = _deriveRole(
            _deriveRootRole(manager),
            adminRoleDescriptionHash
        );
    }
}