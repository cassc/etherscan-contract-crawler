// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelist is Ownable {
    mapping(address => bool) public _whitelist;

    function whitelistAddresses(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++){
            _whitelist[_users[i]] = true;
        }
    }

    function removeAddresses(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++){
            _whitelist[_users[i]] = false;
        }
    }
}