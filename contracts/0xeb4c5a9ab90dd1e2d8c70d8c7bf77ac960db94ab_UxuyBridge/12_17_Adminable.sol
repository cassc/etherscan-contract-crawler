//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Adminable is Context {
    address private _admin;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        _transferAdmin(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if the sender is not the admin.
     */
    function _checkAdmin() internal view virtual {
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current admin.
     *
     * NOTE: Renouncing admin will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdmin() public virtual onlyAdmin {
        _transferAdmin(address(0));
    }

    /**
     * @dev Transfers admin of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdmin(address newAdmin) public virtual onlyAdmin {
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