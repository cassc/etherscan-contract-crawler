// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import { Errors } from "../library/errors/Errors.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are two accounts (an owner and a proxy) that can be granted exclusive
 * access to specific functions. Only the owner can set the proxy.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This contract enables a pattern whereby another contract can be set as a
 * proxy to interact with the inheriting contract with administrative privs.
 * It also enables a pattern whereby the contract owner is never used for
 * general contract admin actions. It's only used to set privileged accounts,
 * while the proxy account operates the contract as the administrator.
 *
 * This module is used through inheritance. It will make available the modifiers
 * `onlyOwner` and `onlyAuthorized`, which can be applied to your functions to
 * restrict their use to the owner or the proxy.
 */
abstract contract ProxyOwnable {
    address public _owner;
    address public _proxy;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current proxy.
     */
    function proxy() public view virtual returns (address) {
        return _proxy;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != msg.sender) revert Errors.UserPermissions();
        _;
    }

    /**
     * @dev Throws if called by any account other than the proxy or the owner.
     */
    modifier onlyAuthorized() {
        if (
            proxy() != msg.sender &&
            owner() != msg.sender
        ) revert Errors.UserPermissions();
        _;
    }

    function checkAuthorized(address operator) public view virtual {
        if (
            proxy() != operator &&
            owner() != operator
        ) revert Errors.UserPermissions();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Errors.AddressTarget(newOwner);
        _setOwner(newOwner);
    }

    /**
     * @dev Sets the proxy for the contract to a new account (`newProxy`).
     * Can only be called by the current owner.
     */
    function setProxy(address newProxy) public virtual onlyOwner {
        _proxy = newProxy;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}