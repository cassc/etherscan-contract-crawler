// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error ALREADY_REGISTERED();
error NOT_REGISTERED();
error START_DATE_IN_FUTURE();
error INVALID_ACTIVITY_MULTIPLIER();

abstract contract MemberRegistry {
    struct Member {
        address account;
        uint32 secondsActive;
        uint32 activityMultiplier;
        uint32 startDate;
    }

    // store when a update happens
    uint32 public lastUpdate;
    // iterable
    Member[] public members;
    uint256 public count = 1;
    mapping(address => uint256) public memberIdxs;

    // EVENTS
    event SetMember(Member member, uint32 startDate);
    event UpdateMemberSeconds(Member member, uint32 newSeconds);
    event UpdateMember(Member member);
    event Update(uint32 date);

    // REGISTERY MODIFIERS

    // add member to registry
    // if member already exists, update their activity multiplier
    // if member does not exist, add them to the registry
    function _setNewMember(
        address _member,
        uint32 _activityMultiplier,
        uint32 _startDate
    ) internal {
        if(memberIdxs[_member] != 0) revert ALREADY_REGISTERED();
        if(_startDate > uint32(block.timestamp)) revert START_DATE_IN_FUTURE();
        if(_activityMultiplier > 100) revert INVALID_ACTIVITY_MULTIPLIER();

        // set to 0, will be updated in next update
        uint32 secsActive = 0;
        members.push(
            Member(_member, secsActive, _activityMultiplier, _startDate)
        );
        memberIdxs[_member] = count;
        emit SetMember(members[count - 1], uint32(block.timestamp)); // index is minus 1 for 0 index array
        count += 1;
    }

    function _updateMember(
        address _member,
        uint32 _activityMultiplier // 0-100 %
    ) internal {
        if(!memberExists(_member)) revert NOT_REGISTERED();
        if(_activityMultiplier > 100) revert INVALID_ACTIVITY_MULTIPLIER();

        members[memberIdxs[_member] - 1]
            .activityMultiplier = _activityMultiplier;
        emit UpdateMember(members[memberIdxs[_member] - 1]);
    }

    // add seconds active to member from last update
    // for brand new members it will be an update from their start date
    // todo: this could be more generic, use a controller contract to update
    function _updateSecondsActive() internal virtual {
        uint32 currentUpdate = uint32(block.timestamp);
        // update struct with total seconds active and seconds in last claim
        for (uint256 i = 0; i < members.length; i++) {
            Member storage _member = members[i];

            uint32 newSeconds = 0;
            if (_member.secondsActive == 0) {
                // new member will be 0 and should get seconds from start date
                newSeconds = (currentUpdate - _member.startDate);
            } else {
                newSeconds = (currentUpdate - lastUpdate);
            }
            // multiple by modifier and divide by 100 to get modifier % of seconds
            uint32 newSecondsActive = (newSeconds *
                _member.activityMultiplier) / 100;
            _member.secondsActive += newSecondsActive;
            emit UpdateMemberSeconds(_member, newSecondsActive);
        }
        lastUpdate = currentUpdate;
        emit Update(currentUpdate);
    }

    function _zeroOutActivityMultiplier(address _account) internal virtual {
        uint256 idx = memberIdxs[_account];
        if(!memberExists(_account)) revert NOT_REGISTERED();
        members[idx - 1].activityMultiplier = 0;
    }

    // GETTERS

    function getMembers() public view returns (Member[] memory) {
        return members;
    }

    function memberExists(address _account) public view returns (bool) {
        return memberIdxs[_account] != 0;
    }

    function getMember(address _account) public view returns (Member memory) {
        uint256 idx = memberIdxs[_account];
        return idx > 0 ? members[idx - 1] : Member(address(0), 0, 0, 0);
    }
}