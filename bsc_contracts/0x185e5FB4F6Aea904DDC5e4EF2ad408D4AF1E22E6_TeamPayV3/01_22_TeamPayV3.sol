// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CZUsd.sol";
import "./libs/IterableMapping.sol";

contract TeamPayV3 is Ownable {
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map teamMemberDailyRateDollars;
    CZUsd czusd;

    mapping(address => uint256) lastUpdateEpoch;

    constructor(CZUsd _czusd) Ownable() {
        czusd = _czusd;
    }

    function getTotalMembers() external view returns (uint256) {
        return teamMemberDailyRateDollars.size();
    }

    function getMemberAtIndex(uint256 i) external view returns (address) {
        return teamMemberDailyRateDollars.getKeyAtIndex(i);
    }

    function getMemberDailyRateDollars(address _for)
        public
        view
        returns (uint256)
    {
        return teamMemberDailyRateDollars.get(_for);
    }

    function setMemberDailyRateDollars(address _for, uint256 _dollarsPerDay)
        external
        onlyOwner
    {
        lastUpdateEpoch[_for] = block.timestamp;
        teamMemberDailyRateDollars.set(_for, _dollarsPerDay);
    }

    function deleteMember(address _for) external onlyOwner {
        delete lastUpdateEpoch[_for];
        teamMemberDailyRateDollars.remove(_for);
    }

    function sendMemberPay(address _for) public {
        uint256 wad = ((block.timestamp - lastUpdateEpoch[_for]) *
            teamMemberDailyRateDollars.get(_for) *
            1 ether) / 1 days;
        czusd.mint(_for, wad);
        lastUpdateEpoch[_for] = block.timestamp;
    }

    function sendMemberPayAll() external {
        for (uint256 i; i < teamMemberDailyRateDollars.size(); i++) {
            sendMemberPay(teamMemberDailyRateDollars.getKeyAtIndex(i));
        }
    }
}