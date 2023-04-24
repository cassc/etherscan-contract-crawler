/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CustomFunctions {
    address private owner;
    event MoonMissionPrepared();
    event StakingRewardsStarted();
    event GovernanceVotingEnabled();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the Memelandlord can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function prepareMoonMission() public onlyOwner {
        emit MoonMissionPrepared();
    }

    function startStakingRewards() public onlyOwner {
        emit StakingRewardsStarted();
    }

    function enableGovernanceVoting() public onlyOwner {
        emit GovernanceVotingEnabled();
    }
}