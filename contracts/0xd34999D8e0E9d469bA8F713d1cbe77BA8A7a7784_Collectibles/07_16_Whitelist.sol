// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title For whitelisting addresses - No limit
abstract contract Whitelist {
    event MemberAdded(address member);
    event MemberRemoved(address member);

    address public owner;
    mapping(address => bool) members;

    function initializeWhitelist(address sender) internal {
        owner = sender;
        members[sender] = true;
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
    function addMember(address _member) external onlyOwner {
        require(!isMember(_member), "Address is member already.");

        members[_member] = true;
        emit MemberAdded(_member);
    }

    /// @notice Remove existing address from whitelist
    /// @param _member Address to be removed
    /// @custom:modifier Owner can not be removed
    /// @custom:modifier Non whitelist member can not be removed
    function removeMember(address _member) external onlyOwner {
        require(isMember(_member), "Not member of whitelist.");
        require(_member != owner, "Owner can not be removed.");

        delete members[_member];
        emit MemberRemoved(_member);
    }
}