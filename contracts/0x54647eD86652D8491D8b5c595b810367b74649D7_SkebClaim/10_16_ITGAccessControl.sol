// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev External interface of TGAccessControl declared to support ERC165 detection.
 */
interface ITGAccessControl {
    /**
     *  @dev Returns `true` if `_account` has admin.
     */
    function hasAdmin(address _account) external view returns (bool);

    /**
     *  @dev Grants admin role to `_account`.
     *
     *  If `account` has not been already granted admin role, emits a {RoleGranted} event.
     *
     * Requirements:
     * - the caller must have admin role.
     */
    function grantAdmin(address _account) external;

    /**
     *  @dev Revokes admin role from `_account`.
     *
     *  If `account` had been already granted admin role, emits a {RoleRevoked} event.
     *
     * Requirements:
     * - the caller must have admin role, not `_account` (cannot revoke from self).
     */
    function revokeAdmin(address _account) external;
}