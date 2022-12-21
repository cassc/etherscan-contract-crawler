// SPDX-License-Identifier: MIT
// A light version of OpenZeppelin access/Ownable.sol (v4.4.1)

pragma solidity ^0.8.4;

error OnlyOwnerAllowedToTransferOwnership();

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 */
abstract contract Ownable {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual {
        if (owner() != msg.sender) revert OnlyOwnerAllowedToTransferOwnership();
        _owner = newOwner;
    }
}