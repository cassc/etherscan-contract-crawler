// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract Admin is OwnableUpgradeable{
    mapping (address => bool) public admins;

    event SetAdmin(address admin, bool auth);

    modifier onlyAdmin() {
        require(
            admins[msg.sender] || owner() == msg.sender,
            "Admin: caller is not the admin"
        );
        _;
    }

    function setAdmin(address _user, bool _auth) external onlyOwner {
        admins[_user] = _auth;
        emit SetAdmin(_user, _auth);
    }
}