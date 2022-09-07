//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AllowList is Ownable {
    event SetAllowed(address addr, bool allowed);
    event SetBypassCheck(bool bypassCheck);

    mapping(address => bool) public allowedMap;
    bool public bypassCheck;

    constructor(address[] memory allowed) {
        for (uint256 i = 0; i < allowed.length; i++) {
            address addr = allowed[i];
            allowedMap[addr] = true;
            emit SetAllowed(addr, true);
        }
    }

    function setAllowance(address addr, bool allowed) public onlyOwner {
        require(!bypassCheck);
        allowedMap[addr] = allowed;
        emit SetAllowed(addr, allowed);
    }

    // open the gates to everyone
    function setBypassCheck(bool _bypassCheck) public onlyOwner {
        bypassCheck = _bypassCheck;
        emit SetBypassCheck(_bypassCheck);
    }

    function getIsAllowed(address addr) public view returns (bool) {
        return bypassCheck || allowedMap[addr];
    }
}