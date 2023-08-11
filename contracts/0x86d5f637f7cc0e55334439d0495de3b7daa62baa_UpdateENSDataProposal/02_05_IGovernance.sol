// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

enum ProposalState {
    Pending,
    Active,
    Defeated,
    Timelocked,
    AwaitingExecution,
    Executed,
    Expired
}

struct Proposal {
    // Creator of the proposal
    address proposer;
    // target addresses for the call to be made
    address target;
    // The block at which voting begins
    uint256 startTime;
    // The block at which voting ends: votes must be cast prior to this block
    uint256 endTime;
    // Current number of votes in favor of this proposal
    uint256 forVotes;
    // Current number of votes in opposition to this proposal
    uint256 againstVotes;
    // Flag marking whether the proposal has been executed
    bool executed;
    // Flag marking whether the proposal voting time has been extended
    // Voting time can be extended once, if the proposal outcome has changed during CLOSING_PERIOD
    bool extended;
}

interface IGovernance {
    function initialized() external view returns (bool);
    function initializing() external view returns (bool);
    function EXECUTION_DELAY() external view returns (uint256);
    function EXECUTION_EXPIRATION() external view returns (uint256);
    function QUORUM_VOTES() external view returns (uint256);
    function PROPOSAL_THRESHOLD() external view returns (uint256);
    function VOTING_DELAY() external view returns (uint256);
    function VOTING_PERIOD() external view returns (uint256);
    function CLOSING_PERIOD() external view returns (uint256);
    function VOTE_EXTEND_TIME() external view returns (uint256);
    function torn() external view returns (address);
    function proposals(uint256 index) external view returns (Proposal memory);
    function proposalCount() external view returns (uint256);
    function lockedBalance(address account) external view returns (uint256);
    function propose(address target, string memory description) external returns (uint256);
    function castVote(uint256 proposalId, bool support) external;
    function lock(address owner, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function unlock(uint256 amount) external;
    function lockWithApproval(uint256 amount) external;
    function execute(uint256 proposalId) external payable;
    function state(uint256 proposalId) external view returns (ProposalState);
}