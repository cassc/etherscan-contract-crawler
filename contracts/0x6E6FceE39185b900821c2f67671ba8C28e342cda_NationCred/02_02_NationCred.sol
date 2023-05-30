//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./INationCred.sol";

/**
 * @notice Stores the passport IDs of active Nation3 citizens.
 */
contract NationCred is INationCred {
    address public owner;

    uint16[] private passportIDs;

    constructor() {
        owner = address(msg.sender);
    }

    function setOwner(address owner_) public {
        require(msg.sender == owner, "You are not the owner");
        owner = owner_;
    }

    function setActiveCitizens(uint16[] calldata passportIDs_) public {
        require(msg.sender == owner, "You are not the owner");
        passportIDs = passportIDs_;
    }

    function isActive(uint16 passportID) public view returns (bool) {
        for (uint16 i = 0; i < passportIDs.length; i++) {
            if (passportIDs[i] == passportID) {
                return true;
            }
        }
        return false;
    }
}