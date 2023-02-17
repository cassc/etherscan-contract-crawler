// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MemberRegistry.sol";

// import "hardhat/console.sol";

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_ACCOUNT();

// DAO member registry
//  - keeps track of members
//  - keeps track of member part/full time activity (activity multiplier)
//  - keeps track of member start date
//  - keeps track of member total seconds active

contract ChampionRegistry is MemberRegistry, Ownable {

    // REGISTERY MODIFIERS

    // add member to registry
    function setNewMember(
        address _member,
        uint32 _activityMultiplier,
        uint32 _startDate
    ) external onlyOwner {
        _setNewMember(_member, _activityMultiplier, _startDate);
    }

    // update member activity multiplier
    function updateMember(address _member, uint32 _activityMultiplier)
        external
        onlyOwner
    {
        _updateMember(_member, _activityMultiplier);
    }

    // BATCH OPERATIONS

    function batchNewMember(
        address[] memory _members,
        uint32[] memory _activityMultipliers,
        uint32[] memory _startDates
    ) external onlyOwner {
        for (uint256 i = 0; i < _members.length; i++) {
            _setNewMember(_members[i], _activityMultipliers[i], _startDates[i]);
        }
    }

    function batchUpdateMember(
        address[] memory _members,
        uint32[] memory _activityMultipliers
    ) external onlyOwner {
        for (uint256 i = 0; i < _members.length; i++) {
            _updateMember(_members[i], _activityMultipliers[i]);
        }
    }

    // MEMBER ACTIONS

    function zeroOutActivityMultiplier() external {
        uint256 idx = memberIdxs[msg.sender];
        if(msg.sender != members[idx - 1].account) revert INVALID_ACCOUNT();
        _zeroOutActivityMultiplier(msg.sender);
    }

    // UPDATE ACTIONS

    // update member total seconds and seconds in last period
    function updateSecondsActive() public {
        _updateSecondsActive();
    }

}