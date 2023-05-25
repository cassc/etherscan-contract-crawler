// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Admins is Ownable{

    mapping(address => bool) private admins;

    /**
    @dev Set the wallet address who can pass the onlyAdmin modifier
    **/
    function setAdminAddress(address _admin, bool _active) public onlyOwner {
        admins[_admin] = _active;
    }

    /**
    @notice Check if the sender is owner() or admin
    **/
    modifier onlyOwnerOrAdmins() {
        require(admins[_msgSender()] == true || owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

}