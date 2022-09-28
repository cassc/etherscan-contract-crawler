// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import { Errors } from "./library/errors/Errors.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract ProxyOwnable is Context {
    address private _owner;
    address private _proxy;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
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
        if (owner() != _msgSender()) revert Errors.UserPermissions();
        _;
    }

    /**
     * @dev Throws if called by any account other than the proxy or the owner.
     */
    modifier onlyAuthorized() {
        if (
            proxy() != _msgSender() &&
            owner() != _msgSender()
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Errors.AddressTarget(newOwner);
        _transferOwnership(newOwner);
    }

    /**
     * @dev Sets the proxy for the contract to a new account (`newProxy`).
     * Can only be called by the current owner.
     */
    function setProxy(address newProxy) public virtual onlyOwner {
        _proxy = newProxy;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}