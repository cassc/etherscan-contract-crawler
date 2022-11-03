// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

/// @title IAdminControl
/// @notice You can use this contract for only the most basic simulation
/// @dev Interface for Admin Control
interface IAdminControl is IERC165 {
    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     *  @dev gets address of all the admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     *  @dev add an admin. Owner only.
     */
    function approveAdmin(address admin) external;

    /**
     *  @dev remove an admin. Owner only.
     */
    function revokeAdmin(address admin) external;

    /**
     *  @dev checks whether the given address is an admin or not. Returns true if they are.
     */
    function isAdmin(address admin) external view returns (bool);
}