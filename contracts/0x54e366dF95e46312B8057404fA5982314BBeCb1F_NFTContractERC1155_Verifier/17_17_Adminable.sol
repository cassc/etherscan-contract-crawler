// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title Adminable made by Artiffine
 * @author https://artiffine.com/
 *
 * Builds on top of Ownable, adds additional admin role.
 */
abstract contract Adminable is Ownable {
    mapping(address => bool) private _admins;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    error CallerIsNotTheAdmin(address caller);
    error AdminAlreadyExists(address admin);
    error AdminDoesNotExist(address admin);
    error AdminIsAddressZero();

    /**
     * @dev Lets only admins to call functions, owner() is also consider an admin.
     */
    modifier onlyAdmin() {
        _checkAdmin(msg.sender);
        _;
    }

    function _checkAdmin(address _admin) internal view {
        if (!_admins[_admin] && _admin != owner()) revert CallerIsNotTheAdmin(_admin);
    }

    /**
     * @dev Adds address to _admins.
     */
    function addAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert AdminIsAddressZero();
        if (_admins[_admin]) revert AdminAlreadyExists(_admin);
        _admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    /**
     * @dev Removes address from _admins.
     */
    function removeAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert AdminIsAddressZero();
        if (!_admins[_admin]) revert AdminDoesNotExist(_admin);
        _admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    /**
     * @dev Returns if the address in as admin.
     */
    function isAdmin(address _admin) external view returns (bool) {
        return _admins[_admin] || _admin == owner();
    }
}