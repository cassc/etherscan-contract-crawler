// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title IAdministrable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for an access control utility allowing any number of addresses to
 * be granted "admin" status and permission to execute functions with the
 * `onlyAdmin` modifier.
 */
interface IAdministrable {
    event AdminGranted(address indexed account, address indexed operator);
    event AdminRevoked(address indexed account, address indexed operator);

    /**
     * @return True iff `account` is an admin.
     * @param account The address that may be an admin.
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * Grants admin status to `account`.
     *
     * Emits an `AdminGranted` event iff `account` was not already an admin.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param account The address to grant admin status
     */
    function grantAdmin(address account) external;

    /**
     * Revokes admin status from `account`.
     *
     * Emits an `AdminRevoked` event iff `account` was an admin until this call.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param account The address from which admin status should be revoked
     */
    function revokeAdmin(address account) external;

    /**
     * Allows the caller to renounce admin status.
     *
     * Emits an `AdminRevoked` event iff the caller was an admin until this
     * call.
     */
    function renounceAdmin() external;
}