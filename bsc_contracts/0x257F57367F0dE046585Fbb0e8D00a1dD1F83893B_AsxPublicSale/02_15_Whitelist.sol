// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Whitelist is AccessControl {
    event MemberAdded(address member);
    event MemberRemoved(address member);
    mapping (address => bool) members;
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WHITELISTER_ROLE, msg.sender);
    }

    /**
     * @dev A method to verify whether an address is a member of the whitelist
     * @param _member The address to verify.
     * @return Whether the address is a member of the whitelist.
     */
    function isMember(address _member) public view returns(bool) {
        return members[_member];
    }

    /**
     * @dev A method to add a member to the whitelist
     * @param _member The member to add as a member.
     */
    function addMember(address _member) public {
        require(hasRole(WHITELISTER_ROLE, msg.sender), "Invalid authorization!");
        require(!isMember(_member), "Address is member already.");

        members[_member] = true;
        emit MemberAdded(_member);
    }

    /**
     * @dev A method to remove a member from the whitelist
     * @param _member The member to remove as a member.
     */
    function removeMember(address _member) public {
        require(hasRole(WHITELISTER_ROLE, msg.sender), "Invalid authorization!");
        require(isMember(_member), "Not member of whitelist.");

        delete members[_member];
        emit MemberRemoved(_member);
    }
}