// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
    function isAdmin(address account) external view returns (bool);
}