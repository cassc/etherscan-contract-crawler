// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Interface for admin role handling
 */
interface IAdminRole {
    function isAdmin(address account) external view returns (bool);
}