// SPDX-License-Identifier: BSD-3-Clause

/// @title Federation

// Federation is an on-chain delegated voter which enables communities
// in the Nouns ecosystem to participate in governance with one another

// Built by wiz ⌐◨-◨ ☆ﾟ. * ･ ｡ﾟ

pragma solidity ^0.8.16;

import {NounsDAOStorageV1} from "./external/nouns/governance/NounsDAOInterfaces.sol";

/// @notice All possible states that a proposal may be in
enum ProposalState {
    Active,
    Expired,
    Executed,
    Vetoed
}

/// @notice All possible results for a proposal
enum ProposalResult {
    For,
    Against,
    Abstain,
    Undecided
}

/// @notice A delegate action is a proposal for how the Federation delegate should
/// vote on an external proposal.
struct DelegateAction {
    /// @notice Unique id for looking up a proposal
    uint256 id;
    /// @notice Creator of the proposal
    address proposer;
    /// @notice Implementation of external DAO proposal reference is for
    address eDAO;
    /// @notice Id of the external proposal reference in the external DAO
    uint256 eID;
    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
    uint256 quorumVotes;
    /// @notice The block at which voting begins: holders must delegate their votes prior to this block
    uint256 startBlock;
    /// @notice The block at which voting ends: votes must be cast prior to this block
    uint256 endBlock;
    /// @notice Current number of votes in favor of this proposal
    uint256 forVotes;
    /// @notice Current number of votes in opposition to this proposal
    uint256 againstVotes;
    /// @notice Current number of votes for abstaining for this proposal
    uint256 abstainVotes;    
    /// @notice Flag marking whether the proposal has been vetoed
    bool vetoed;
    /// @notice Flag marking whether the proposal has been executed
    bool executed;
    /// @notice Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
}

/// @notice Ballot receipt record for a voter
struct Receipt {
    /// @notice Whether or not a vote has been cast
    bool hasVoted;
    /// @notice Whether or not the voter supports the proposal or abstains
    uint8 support;
    /// @notice The number of votes the voter had, which were cast
    uint96 votes;
}

contract DelegateEvents {
    event ProposalCreated(
        uint256 id,
        address proposer,
        address indexed eDAO,
        uint256 indexed ePropID,
        uint256 startBlock,
        uint256 endBlock,
        uint256 quorumVotes
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 votes,
        string reason
    );

    /// @notice An event emitted when a proposal has been executed in the NounsDAOExecutor
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 id);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);

    /// @notice Emitted when exec window is changed
    event NewExecWindow(uint256 oldExecWindow, uint256 newExecWindow);
}

interface INounsDAOGovernance {
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function castVote(uint256 proposalId, uint8 support) external;

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external;

    function state(uint256 proposalId) external view returns (NounsDAOStorageV1.ProposalState);

    function quorumVotes() external view returns (uint256);
    
    function proposalThreshold() external view returns (uint256);
}