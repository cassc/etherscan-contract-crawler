// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title For whitelisting addresses
abstract contract Whitelist {
    event MemberAdded(address member);
    event MemberRemoved(address member);

    uint8 private total_members;
    address public owner;
    mapping(address => bool) members;

    function initializeWhitelist(address sender) internal {
        owner = sender;
        members[sender] = true;
        total_members++;
        emit MemberAdded(sender);
    }

    modifier onlyWhitelist() {
        require(isMember(msg.sender), "Only whitelisted.");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner.");
        _;
    }

    /// @notice Checks if supplied address is member or not
    /// @param _member Address to be checked
    /// @return Returns boolean
    function isMember(address _member) public view returns (bool) {
        return members[_member];
    }

    /// @notice Adds new address as whitelist member
    /// @param _member Address to be whitelisted
    /// @custom:modifier Maximum 3 whitelist members are allowed
    function addMember(address _member) external onlyWhitelist {
        require(!isMember(_member), "Address is member already.");
        require(total_members < 3, "Only 3 whitelist members allowed.");

        total_members++;
        members[_member] = true;
        emit MemberAdded(_member);
    }

    /// @notice Removed existing address from whitelist
    /// @param _member Address to be removed
    /// @custom:modifier Owner can not be removed
    /// @custom:modifier Non whitelist member can be remove members
    function removeMember(address _member) external onlyOwner {
        require(isMember(_member), "Not member of whitelist.");
        require(_member != owner, "Owner can not be removed.");

        total_members--;
        delete members[_member];
        emit MemberRemoved(_member);
    }
}