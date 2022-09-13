// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


abstract contract Groupable {

    constructor() {}


    /*########## OBSERVERS ##########*/

    // INTERNAL - returns TRUE if account is member of the given group, FALSE otherwise
    function isGroupMember(uint256 groupIndex, address account) internal view virtual returns (bool);

    // INTERNAL - returns TRUE if the gruop is active (>=1 members), FALSE otherwise
    function isGroupActive(uint256 groupIndex) internal view virtual returns (bool);

    // INTERNAL - returns the number of members of the given group
    function getGroupMemberNumber(uint256 groupIndex) internal view virtual returns (uint256);

    // INTERNAL - returns an array containing the members of the given group
    function getGroupMembers(uint256 groupIndex) internal view virtual returns (address[] memory);

    /*########## MODIFIERS ##########*/

    // INTERNAL - creates a group with "account" in it
    function addGroup(address account) internal virtual returns (uint256);

    // INTERNAL - creates a group with a list of accounts in it
    function addGroup(address[] calldata account) internal virtual returns (uint256);

    // INTERNAL adds a single member to the given group
    function addMemberToGroup(uint256 groupIndex, address account) internal virtual returns (bool);

    // INTERNAL adds a list of members to the given group
    function addMemberToGroup(uint256 groupIndex, address[] calldata account) internal virtual returns (bool);

    // INTERNAL - disables the given group
    function removeGroup(uint256 groupIndex) internal virtual returns (bool);
    // INTERNAL - removes the account from the given group

    function removeMemberFromGroup(uint256 groupIndex, address account) internal virtual returns (bool);


    function beforeAddingMemberToGroup(uint256 groupIndex, address account) internal virtual;

    function beforeRemovingMemberFromGroup(uint256 groupIndex, address account) internal virtual;
    
}