// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ISafeOwnable.sol";

/**
 * @title Safe Ownable
 * @author 0x0Louis
 * @notice This contract is used to manage the ownership of a contract in a two-step process.
 */
abstract contract SafeOwnable is ISafeOwnable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Modifier that checks if the caller is the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != owner()) revert SafeOwnable__OnlyOwner();
        _;
    }

    /**
     * @dev Modifier that checks if the caller is the pending owner.
     */
    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner()) revert SafeOwnable__OnlyPendingOwner();
        _;
    }

    /**
     * @notice Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @notice Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual override returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Sets the pending owner to a new address.
     * @param newOwner The address to transfer ownership to.
     */
    function setPendingOwner(address newOwner) public virtual override onlyOwner {
        _setPendingOwner(newOwner);
    }

    /**
     * @notice Accepts ownership of the contract.
     * @dev Can only be called by the pending owner.
     */
    function becomeOwner() public virtual override onlyPendingOwner {
        address newOwner = _pendingOwner;

        _setPendingOwner(address(0));
        _transferOwnership(newOwner);
    }

    /**
     * Private Functions
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Sets the pending owner to a new address.
     * @param newPendingOwner The address to transfer ownership to.
     */
    function _setPendingOwner(address newPendingOwner) internal virtual {
        _pendingOwner = newPendingOwner;
        emit PendingOwnerSet(msg.sender, newPendingOwner);
    }
}