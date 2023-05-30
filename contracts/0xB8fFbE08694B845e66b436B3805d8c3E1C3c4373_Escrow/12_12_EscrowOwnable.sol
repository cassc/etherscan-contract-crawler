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
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract EscrowOwnable {
    address private _owner;
    address private _proxy;
    address private _banker;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
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
     * @dev Returns the address of the current proxy.
     */
    function banker() public view virtual returns (address) {
        return _banker;
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
            banker() != msg.sender &&
            owner() != msg.sender
        ) revert Errors.UserPermissions();
        _;
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

    /**
     * @dev Sets the proxy for the contract to a new account (`newProxy`).
     * Can only be called by the current owner.
     */
    function setBanker(address newBanker) public virtual onlyOwner {
        _banker = newBanker;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}