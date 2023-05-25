// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Access is Ownable {

    mapping(address => bool) public isAdmin;
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] || msg.sender == owner(), "underground: only admin");
        _;
    }

    function addAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = true;
    }

    function addAdmins(address[] calldata _admins) external onlyOwner {
        uint256 l = _admins.length;
        for(uint256 i = 0; i < l; i++) {
            isAdmin[_admins[i]] = true;
        }
    }

    function removeAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = false;
    }

    function removeAdmins(address[] calldata _admins) external onlyOwner {
        uint256 l = _admins.length;
        for(uint256 i = 0; i < l; i++) {
            isAdmin[_admins[i]] = false;
        }
    }
}