// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title A contract that combines OpenZeppelin's `Ownable` with `AccessControl`.
 * @dev We make two critical assumptions here:
 * - no 2-step ownership handover,
 * - the role `DEFAULT_ADMIN_ROLE` cannot be ever renounced, i.e.
 * assigned to the zero address.
 */
abstract contract AccessContrownable is Ownable, AccessControl {
    address private defaultAdminAddr;

    /**
     * @dev Error that occurs when the function is not implemented.
     * @param emitter The contract that emits the error.
     */
    error NotImplemented(address emitter);

    /**
     * @dev Error that occurs when the operation is not allowed.
     * @param emitter The contract that emits the error.
     */
    error OperationNotAllowed(address emitter);

    constructor(address admin_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        defaultAdminAddr = admin_;
    }

    function owner() public view virtual override returns (address) {
        return defaultAdminAddr;
    }

    function renounceOwnership() public view virtual override {
        revert NotImplemented(address(this));
    }

    function transferOwnership(address) public view virtual override {
        revert NotImplemented(address(this));
    }

    function grantRole(
        bytes32 role,
        address account
    ) public virtual override onlyOwner {
        /**
         * @dev If we update the `DEFAULT_ADMIN_ROLE` role, we revoke the role from the
         * previous owner and set it to the new `defaultAdminAddr`, which is used to
         * track the `owner`.
         */
        if (role == DEFAULT_ADMIN_ROLE) {
            _revokeRole(role, defaultAdminAddr);
            defaultAdminAddr = account;
            emit OwnershipTransferred(msg.sender, account);
        }
        _grantRole(role, account);
    }

    /**
     * @dev Since the role `DEFAULT_ADMIN_ROLE` is always assigned to `owner` and
     * only one single address is attached to it, we use the modifier `onlyOwner`
     * instead of `onlyRole(getRoleAdmin(role))`.
     */
    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override onlyOwner {
        /**
         * @dev Revoking the `DEFAULT_ADMIN_ROLE` role is disabled.
         */
        if (role == DEFAULT_ADMIN_ROLE) {
            revert OperationNotAllowed(address(this));
        }
        _revokeRole(role, account);
    }

    function renounceRole(
        bytes32 role,
        address account
    ) public virtual override {
        /**
         * @dev Renouncing the `DEFAULT_ADMIN_ROLE` role is disabled.
         */
        if (role == DEFAULT_ADMIN_ROLE) {
            revert OperationNotAllowed(address(this));
        }
        super.renounceRole(role, account);
    }
}