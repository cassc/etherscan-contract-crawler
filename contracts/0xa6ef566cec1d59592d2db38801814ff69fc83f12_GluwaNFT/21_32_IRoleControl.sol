// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRoleControl {
    /// @notice Return if a address has admin role
    /// @param account The address to verify
    /// @return True if the address has admin role
    function isAdmin(address account) external returns (bool);

    /// @notice Give Admin Role to the given address.
    /// @param account The address to give the Admin Role.
    /// @dev The call must originate from an admin.
    function addAdmin(address account) external;

    /// @notice Revoke Admin Role from the given address.
    /// @param account The address to revoke the Admin Role.
    /// @dev The call must originate from an admin.
    function removeAdmin(address account) external;
}