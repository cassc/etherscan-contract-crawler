// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDispute {
    struct Dispute {
        uint256 escrowId;
        uint256 approvedCount; // (default: 0)
        uint256 disapprovedCount; // (default: 0)
        uint256 status; // (default: 0)  1: init, 2: waiting, 3: review, 4: win, 4: fail
        uint256 applied_agents_count;
        uint256 createdAt;
        uint256 updatedAt;
    }
    event Disputed(
        address indexed _from,
        uint256 indexed _disputeId,
        uint256 indexed _escrowId
    );
    event SubmittedDispute(
        address indexed _agentAddress,
        uint256 indexed _disputeId,
        uint256 indexed _decision
    );

    event DisputeApproved(uint256 indexed _disputeId);
    event DisputeDisapproved(uint256 indexed _disputeId);
}