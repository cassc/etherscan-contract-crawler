// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAgent {
    struct Agent {
        uint256 score; // (default: initial_agent_score)
        uint256 participationCount;
        uint256 accumulatedAmount;
        uint256 assignedDisputeId;
        uint256 status;
    }
    event AgentParticipated(address indexed _agentAddress);
    event AssignAgent(
        address indexed _agentAddress,
        uint256 indexed _disputeId
    );
    event AgentWithdraw(address indexed _withdrawer, uint256 _amount);
}