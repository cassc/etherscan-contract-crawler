// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Restricted is Ownable {

    mapping(address => bool) public admin;

    modifier restrictToAdmins {
        require(msg.sender == owner() || admin[msg.sender], 
            "error: unauthorized access"
        );
        _;
    }

    function addAdmins (
        address[] calldata _addresses 
    ) external onlyOwner {
        uint len = _addresses.length;
        for (uint i = 0; i < len;) {
            admin[_addresses[i]] = true;
            unchecked {
                i++;
            }
        }
    }

    function removeAdmins (
        address[] calldata _addresses 
    ) external onlyOwner {
        uint len = _addresses.length;
        for (uint i = 0; i < len;) {
            admin[_addresses[i]] = false;
            unchecked {
                i++;
            }
        }
    }
}