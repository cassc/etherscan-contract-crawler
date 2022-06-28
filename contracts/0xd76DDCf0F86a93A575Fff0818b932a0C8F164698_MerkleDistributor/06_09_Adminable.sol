// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Adminable
 */
abstract contract Adminable is Ownable {
    mapping(address => bool) public isAdmin;

    event SetAdminPermission(address indexed admin, bool permission);

    modifier onlyAdmin {
        require(isAdmin[msg.sender], "Adminable: caller is not the admin");
        _;
    }

    modifier onlyOwnerOrAdmin {
        require((owner() == msg.sender) || isAdmin[msg.sender], "Adminable: caller is not the owner or admin");
        _;
    }


    // ** ONLY OWNER functions **

    function setAdminPermission(address _user, bool _permission) external onlyOwner {
        isAdmin[_user] = _permission;
        emit SetAdminPermission(_user, _permission);
    }
}