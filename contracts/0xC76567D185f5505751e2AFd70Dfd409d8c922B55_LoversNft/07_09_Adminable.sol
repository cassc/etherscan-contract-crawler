// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Adminable is Ownable {
    address private _admin;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner and admin.
     */
    constructor(address admin_) {
        _transferOwnership(_msgSender());
        _transferAdmin(admin_);
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    error NotAdmin();
    error NotOwnerNorAdmin();

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        if(admin() != _msgSender()) {
            revert NotAdmin();
        }
        _;
        // require(admin() == _msgSender(), "Adminable: caller is not the admin");
        // _;
    }

    /**
     * @dev Throws if called by any account other than the owner nor the admin.
     */
    modifier onlyOwnerOrAdmin() {
        if(admin() != _msgSender() && owner() != _msgSender()) {
            revert NotOwnerNorAdmin();
        }
        _;

        // require(admin() == _msgSender() || owner() == _msgSender(), "Adminable: caller is not the owner nor the admin");
        // _;
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing admin will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdmin() public virtual onlyOwner {
        _transferAdmin(address(0));
    }

    /**
     * @dev Transfers admin of the contract to a new account (`newAdmin`).
     * Can only be called by the current owner.
     */
    function transferAdmin(address newAdmin) public virtual onlyOwner {
        require(newAdmin != address(0), "Adminable: new admin is the zero address");
        _transferAdmin(newAdmin);
    }

    /**
     * @dev Transfers admin of the contract to a new account (`newAdmin`).
     * Internal function without access restriction.
     */
    function _transferAdmin(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }
}