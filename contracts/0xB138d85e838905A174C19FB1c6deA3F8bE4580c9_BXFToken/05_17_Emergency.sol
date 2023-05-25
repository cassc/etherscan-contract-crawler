// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Founder.sol";


abstract contract Emergency is Founder {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 constant public EMERGENCY_MANAGER_ROLE = keccak256("EMERGENCY_MANAGER_ROLE");

    EnumerableSet.AddressSet private _emergencyVotes;

    uint256 private _emergencyThresholdCount;
    bool private _emergencyVotingStarted = false;

    event EmergencyVotingStarted();
    event EmergencyWithdraw(address account, uint256 amount);


    function isEmergencyCase() public view returns(bool) {
        return _emergencyVotingStarted;
    }


    function emergencyContractBalanceWithdraw() public {
        require(hasRole(EMERGENCY_MANAGER_ROLE, msg.sender), "Emergency: you're not allowed to do this");
        require(emergencyVotesCount() >= emergencyVotingThresholdCount(), "Emergency: not enough votes for performing emergency withdraw");

        msg.sender.transfer(address(this).balance);
        emit EmergencyWithdraw(msg.sender, address(this).balance);
    }


    function voteForEmergencyCase() public returns(bool) {
        require(_emergencyVotingStarted, "Emergency: emergency voting is not activated");
        require(isFounder(msg.sender), "Emergency: only founders have right to vote for emergency cases");

        return _emergencyVotes.add(msg.sender);
    }


    function emergencyVotesCount() public view returns(uint256) {
        return _emergencyVotes.length();
    }


    function emergencyVotingThresholdCount() public view returns(uint256) {
        return _emergencyThresholdCount;
    }


    function hasVotedForEmergency(address account) public view returns(bool) {
        return _emergencyVotes.contains(account);
    }


    function startEmergencyVote(uint256 thresholdCount) public {
        require(hasRole(EMERGENCY_MANAGER_ROLE, msg.sender), "Emergency: you're not allowed to start emergency vote");
        require(0 < thresholdCount && thresholdCount <= getFoundersCount(), "Emergency: please set right threshold");

        _emergencyVotingStarted = true;
        _emergencyThresholdCount = thresholdCount;

        emit EmergencyVotingStarted();
    }
}