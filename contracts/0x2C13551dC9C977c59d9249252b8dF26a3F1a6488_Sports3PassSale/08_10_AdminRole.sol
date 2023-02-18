// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AdminRole {
    address private _admin;

    event AdminTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    constructor() {
        _transferAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(admin() == msg.sender, "caller is not the admin");
        _;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function _transferAdmin(address newAdmin) internal virtual {
        require(newAdmin != address(0), "invalid address");
        require(newAdmin != _admin, "not change admin");
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, _admin);
    }
}