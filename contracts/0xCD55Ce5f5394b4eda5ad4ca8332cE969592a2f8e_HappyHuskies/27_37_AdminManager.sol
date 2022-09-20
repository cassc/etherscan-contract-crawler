//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract AdminManager {
    mapping(address => bool) internal _admins;

    constructor() {
        _admins[msg.sender] = true;
        _admins[address(this)] = true;
    }

    function setAdminPermissions(address account_, bool enable_)
        external
        onlyAdmin
    {
        _admins[account_] = enable_;
    }

    function isAdmin(address account_) public view returns (bool) {
        return _admins[account_];
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not an admin");
        _;
    }
}