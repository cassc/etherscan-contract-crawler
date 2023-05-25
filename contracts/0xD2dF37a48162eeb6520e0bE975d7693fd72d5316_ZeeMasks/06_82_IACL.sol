// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/// @notice Access Control List contract interface.
interface IACL is IAccessControlEnumerableUpgradeable {
    error RolesContractIncorrectlyConfigured();
    error CannotHaveMoreThanOneAddressInRole();
    error CannotRemoveLastAdmin();

    /// @notice revert if the `account` does not have the specified role.
    /// @param role the role specifier.
    /// @param account the address to check the role for.
    function checkRole(bytes32 role, address account) external view;

    /// @notice Get the admin role describing bytes.
    /// @return role bytes.
    function getAdminRole() external pure returns (bytes32);

    /// @notice Get the maintainer role describing bytes.
    /// @return role bytes.
    function getMaintainerRole() external pure returns (bytes32);
}