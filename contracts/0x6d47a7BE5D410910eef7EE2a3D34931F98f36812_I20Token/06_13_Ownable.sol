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
abstract contract Ownable is Context {
    address private _owner;
    address[] private _admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Adds new admin.

   function addAdmin(address newAddress) public onlyOwner {
        if(!isWalletAdmin(newAddress)){
            _admins.push(newAddress);
        }
   }

    /// @dev removes admin wallet by index.
    /// @param index_ index of the wallet.

   function removeAdminByIndex(uint index_) private onlyOwner {
        require(index_ < _admins.length, "index out of bound");
        while (index_ < _admins.length - 1) {
            _admins[index_] = _admins[index_ + 1];
            index_++;
        }
        _admins.pop();
    }

    /// @dev finds the index of the address in admin
    /// @param address_ address of the wallet.
    
    function findAdminIndex(address address_) private view returns(uint) {
        uint i = 0;
        while (_admins[i] != address_) {
            i++;
        }
        return i;
    }

    /// @dev removes admin wallet by address
    /// @param address_ address of the wallet.

    function removeAdminWithAddress(address address_) public onlyOwner {
        uint index = findAdminIndex(address_);
        removeAdminByIndex(index);
    }

    /// @dev Returns list of admin.
    /// @return List of admin addresses.

    function getAdmins() public view onlyAdminOrOwner returns (address[] memory) {
        return _admins;
    }
    
    /// @dev Checks if address is in admins.
    /// @param address_ address of the wallet.
    /// @return true if address is in white list.
    
    function isWalletAdmin(address address_) private view returns (bool) {
    if(_admins.length == 0) {
        return false;
    }

    for (uint i = 0; i < _admins.length; i++) {
        if (_admins[i] == address_) {
            return true;
        }
    }
        return false;
    }



    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Throws if called by any account other than the admin.
     */

    modifier onlyAdmin() {
        require(isWalletAdmin(_msgSender()) , "Ownable: caller is not the admin");
        _;
    }

        /**
     * @dev Throws if called by any account other than the admin.
     */

    modifier onlyAdminOrOwner() {
        require(isWalletAdmin(_msgSender()) || _msgSender() == owner() , "Ownable: caller is not the admin or owner");
        _;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}