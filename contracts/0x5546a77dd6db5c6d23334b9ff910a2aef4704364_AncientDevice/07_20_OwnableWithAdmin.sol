// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
abstract contract OwnableWithAdmin is Context {
    address private _owner;
    address private _admin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewAdmin(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "OwnableWithAdmin: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner or the admin.
     */
    modifier onlyOwnerOrAdmin() {
        require(owner() == _msgSender() || admin() == _msgSender(), "OwnableWithAdmin: caller is not the owner or admin");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner forever.
     * NOTE: This function does not remove the admin, so onlyOwnerOrAdmin function 
     * can still be called if an admin was set prior to the renouncing of ownership.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Leaves the contract without owner or admin. It will not be possible to call
     * onlyOwner or onlyOwnerOrAdmin functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership and adminship will leave the contract without an owner or an admin,
     * thereby removing any functionality that is only available to the owner or admin forever.
     */
    function renounceOwnershipandAdminship() public virtual onlyOwner {
        _setOwner(address(0));
        _setAdmin(address(0));
    }

    

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner can't be the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setAdmin(address newAdmin) public virtual onlyOwner {
        require(newAdmin != address(0), "Ownable: new admin can't be the zero address");
        _setAdmin(newAdmin);
    }
    function _setAdmin(address newAdmin) private {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit NewAdmin(oldAdmin, newAdmin);
    }
}