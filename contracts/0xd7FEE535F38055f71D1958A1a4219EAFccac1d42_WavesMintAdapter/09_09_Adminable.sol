// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Adminable {
    event AdminUpdated(address sender, address oldAdmin, address admin);

    address public admin;

    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin");
        _;
    }

    function updateAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), "zero address");
        emit AdminUpdated(msg.sender, admin, admin_);
        admin = admin_;
    }
}