pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

interface IDarwinCommunity {
    event ActiveFundCandidateRemoved(uint256 indexed id);
    event ActiveFundCandidateAdded(uint256 indexed id);

    event NewFundCandidate(uint256 indexed id, address valueAddress, string proposal);
    event FundCandidateDeactivated(uint256 indexed id);

    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        uint256 startTime,
        uint256 endTime,
        string title,
        string description,
        string other
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param inSupport Is the vote is favour
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool inSupport);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 indexed id);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 indexed id);

    event ExecuteTransaction(
        uint256 indexed id,
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data
    );

    event CommunityFundDistributed(uint256 fundWeek, uint256[] candidates, uint256[] tokens);

    function setDarwinAddress(address account) external;

}