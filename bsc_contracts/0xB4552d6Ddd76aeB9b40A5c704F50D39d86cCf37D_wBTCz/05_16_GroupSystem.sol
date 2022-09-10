// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Groupable.sol";


contract GroupSystem is Groupable {
    
    struct Group{
        mapping (address => bool) isMember;
        mapping (uint256 => address) memberList;
        uint256 firstEmptyMember;
    }
    mapping (uint256 => Group) private _groupList;
    uint256 private _firstEmptyGroup;

    constructor() {}


    /*########## OBSERVERS ##########*/

    // INTERNAL - returns TRUE if account is member of the given group, FALSE otherwise
    function isGroupMember(uint256 groupIndex, address account) internal view override returns (bool) {
        return _groupList[groupIndex].isMember[account];
    }

    // INTERNAL - returns TRUE if the gruop is active (>=1 members), FALSE otherwise
    function isGroupActive(uint256 groupIndex) internal view override returns (bool) {
        return (_groupList[groupIndex].firstEmptyMember!=0);
    }

    // INTERNAL - returns the number of members of the given group
    function getGroupMemberNumber(uint256 groupIndex) internal view override returns (uint256){
        return _groupList[groupIndex].firstEmptyMember;
    }

    // INTERNAL - returns an array containing the members of the given group
    function getGroupMembers(uint256 groupIndex) internal view override returns (address[] memory){
        //Be careful, limitations should applied in caller class
        //possible crash if returned array too big
        return _getGroupMembers(groupIndex);
    }

    /*########## MODIFIERS ##########*/

    // INTERNAL - creates a group with "account" in it
    function addGroup(address account) internal override returns (uint256) {
        _addMemberToGroup(_firstEmptyGroup, account);
        return _firstEmptyGroup++;
    }

    // INTERNAL - creates a group with a list of accounts in it
    function addGroup(address[] calldata account) internal override returns (uint256) {
        _addMemberToGroup(_firstEmptyGroup, account);
        return _firstEmptyGroup++;
    }

    // INTERNAL adds a single member to the given group
    function addMemberToGroup(uint256 groupIndex, address account) internal override returns (bool) {
        if(isGroupActive(groupIndex)==false){
            return false;
        }
        _addMemberToGroup(groupIndex, account);
        return true;
    }

    // INTERNAL adds a list of members to the given group
    function addMemberToGroup(uint256 groupIndex, address[] calldata account) internal override returns (bool) {
        if(isGroupActive(groupIndex)==false){
            return false;
        }
        _addMemberToGroup(groupIndex, account);
        return true;
    }

    // INTERNAL - disables the given group
    function removeGroup(uint256 groupIndex) internal override returns (bool) {
        return _removeGroup(groupIndex);
    }
    // INTERNAL - removes the account from the given group
    function removeMemberFromGroup(uint256 groupIndex, address account) internal override returns (bool) {
        return _removeMemberFromGroup(groupIndex, account);
    }


    /*########## ADMINISTRATIVE TOOLS ##########*/

    function _getGroupMembers(uint256 groupIndex) private view returns (address[] memory) {
        uint256 FEM=_groupList[groupIndex].firstEmptyMember;
        address[] memory members = new address[](FEM);
        for(uint256 i = 0; i < FEM; ++i) {
            members[i]=_groupList[groupIndex].memberList[i];
        }
        return members;
    }
    // PRIVATE - implements addMemberToGroup
    function _addMemberToGroup(uint256 groupIndex, address account) private {
        beforeAddingMemberToGroup(groupIndex, account);
        if(_groupList[groupIndex].isMember[account]==true){
            return;
        }
        _groupList[groupIndex].isMember[account]=true;
        _groupList[groupIndex].memberList[_groupList[groupIndex].firstEmptyMember++]=account;
        return;
    }

    // PRIVATE - implements addMemberToGroup
    function _addMemberToGroup(uint256 groupIndex, address[] calldata account) private {
        for(uint256 i=0; i<account.length; ++i){
            _addMemberToGroup(groupIndex, account[i]);
        }
    }
	
    // PRIVATE - implements removeMemberFromGroup
    function _removeMemberFromGroup(uint256 groupIndex, address account) private returns (bool) {
        beforeRemovingMemberFromGroup(groupIndex, account);
        if(_groupList[groupIndex].isMember[account]==false){
            return true;
        }
        uint256 FEM=_groupList[groupIndex].firstEmptyMember;
        if(FEM<2){
            return false;
        }
        _groupList[groupIndex].isMember[account]=false;
        for(uint256 i=0; i<FEM; ++i){
            if(_groupList[groupIndex].memberList[i]==account){
                _groupList[groupIndex].memberList[i]=_groupList[groupIndex].memberList[--FEM];
                _groupList[groupIndex].firstEmptyMember=FEM;
                return true;
            }
        }
        return false;
    }
    // PRIVATE - implements removeGroup
    function _removeGroup(uint256 groupIndex) private returns (bool) {
        _groupList[groupIndex].firstEmptyMember=0;
        return true;
    }

    function beforeAddingMemberToGroup(uint256 groupIndex, address account) internal virtual override {}

    function beforeRemovingMemberFromGroup(uint256 groupIndex, address account) internal virtual override {}
    
}