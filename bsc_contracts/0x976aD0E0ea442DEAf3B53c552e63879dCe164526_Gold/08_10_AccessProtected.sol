// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";

abstract contract AccessProtected is Ownable {
    mapping(address => bool) public admins;

    event AdminAccessSet(address _admin, bool _enabled);

    function setAdmin(address admin, bool enabled) external onlyOwner {
        admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    function isAdmin(address admin) public view returns (bool) {
        return admins[admin];
    }

    modifier onlyAdmin() {
        require(
            admins[_msgSender()] || _msgSender() == owner(),
            "AccessProtected: Caller does not have Admin Access"
        );
        _;
    }
}