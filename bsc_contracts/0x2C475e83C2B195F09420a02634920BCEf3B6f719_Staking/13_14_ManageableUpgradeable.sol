/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ManageableUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _managers;
    event ManagerAdded(address indexed manager_);
    event ManagerRemoved(address indexed manager_);

    function managers(address manager_) public view virtual returns (bool) {
        return _managers[manager_];
    }

    modifier onlyManager() {
        require(_managers[_msgSender()], "Manageable: caller is not the owner");
        _;
    }

    function removeManager(address manager_) public virtual onlyOwner {
        _managers[manager_] = false;
        emit ManagerRemoved(manager_);
    }

    function addManager(address manager_) public virtual onlyOwner {
        require(
            manager_ != address(0),
            "Manageable: new owner is the zero address"
        );
        _managers[manager_] = true;
        emit ManagerAdded(manager_);
    }
}