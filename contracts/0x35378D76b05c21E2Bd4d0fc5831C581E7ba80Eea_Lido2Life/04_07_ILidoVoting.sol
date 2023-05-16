// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// enum VotePhase { Main, Objection, Closed }

interface ILidoVoting {
    function executeVote(uint256 _voteId) external;
    function canExecute(uint256 _voteId) external view returns (bool);
    function getVote(uint256 _voteId)
        external
        view
        returns (
            bool open,
            bool executed,
            uint64 startDate,
            uint64 snapshotBlock,
            uint64 supportRequired,
            uint64 minAcceptQuorum,
            uint256 yea,
            uint256 nay,
            uint256 votingPower
        );
    // bytes memory script,
    // VotePhase phase
}