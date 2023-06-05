// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Context.sol";

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
 *
 * This is a modified version of the openzeppelin Ownable contract which works
 * with the cloneable contract pattern. Instead of initializing ownership in the
 * constructor, we have an empty constructor and then perform setup in the
 * initializeOwnership function.
 */
abstract contract OwnableCloneable is Context {
    bool ownableInitialized;
    address private _owner;

    modifier ownershipInitialized() {
        require(ownableInitialized, "OwnableCloneable: hasn't been initialized yet.");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the initialize caller as the initial owner.
     */
    function initializeOwnership(address initialOwner) public virtual {
        require(!ownableInitialized, "OwnableCloneable: already initialized.");
        ownableInitialized = true;
        _setOwner(initialOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual ownershipInitialized returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "OwnableCloneable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual ownershipInitialized onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual ownershipInitialized onlyOwner {
        require(newOwner != address(0), "OwnableCloneable: new owner is the zero address");
        _setOwner(newOwner);
    }

    // This is set to internal so overriden versions of renounce/transfer ownership
    // can also be carried out by DAO address.
    function _setOwner(address newOwner) internal ownershipInitialized {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}