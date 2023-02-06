// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IAdministrable} from "./IAdministrable.sol";

/**
 * @title Administrable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Access control utility allowing any number of addresses to be granted "admin"
 * status and permission to execute functions with the `onlyAdmin` modifier.
 */
abstract contract Administrable is Context, IAdministrable {
    mapping(address => bool) private _admins;

    /**
     * Initializes `Administrable` with the caller as the original admin.
     *
     * Emits an `AdminGranted` event.
     */
    constructor() {
        _grantAdmin(_msgSender());
    }

    modifier onlyAdmin() virtual {
        _checkAdmin();
        _;
    }

    /**
     * @return True iff `account` is an admin.
     * @param account The address that may be an admin.
     */
    function isAdmin(address account) public view virtual returns (bool) {
        return _admins[account];
    }

    /**
     * Internal helper function that reverts if the caller is not an admin.
     */
    function _checkAdmin() internal view virtual {
        require(isAdmin(_msgSender()), "Administrable: admin-only function");
    }

    /**
     * Grants admin status to `account`.
     *
     * Emits an `AdminGranted` event iff `account` was not already an admin.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param account The address to grant admin status
     */
    function grantAdmin(address account) public virtual onlyAdmin {
        _grantAdmin(account);
    }

    /**
     * Revokes admin status from `account`.
     *
     * Emits an `AdminRevoked` event iff `account` was an admin until this call.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param account The address from which admin status should be revoked
     */
    function revokeAdmin(address account) public virtual onlyAdmin {
        _revokeAdmin(account);
    }

    /**
     * Allows the caller to renounce admin status.
     *
     * Emits an `AdminRevoked` event iff the caller was an admin until this
     * call.
     */
    function renounceAdmin() public virtual {
        _revokeAdmin(_msgSender());
    }

    /**
     * Grants admin status to `account`.
     *
     * Emits an `AdminGranted` event iff `account` was not already an admin.
     * @param account The address to grant admin status
     */
    function _grantAdmin(address account) internal virtual {
        if (!isAdmin(account)) {
            _admins[account] = true;
            emit AdminGranted(account, _msgSender());
        }
    }

    /**
     * Revokes admin status from `account`.
     *
     * Emits an `AdminRevoked` event iff `account` was an admin until this call.
     * @param account The address from which admin status should be revoked
     */
    function _revokeAdmin(address account) internal virtual {
        if (isAdmin(account)) {
            _admins[account] = false;
            emit AdminRevoked(account, _msgSender());
        }
    }
}