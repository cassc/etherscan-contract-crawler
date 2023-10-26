//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

struct Proposal {
    address proposer;
    uint256 start;
    uint256 end;
    uint256 totalForVotes;
    uint256 totalAgainstVotes;
    mapping(uint256 => uint256) forVotes; // votingRightId => for vote amount
    mapping(uint256 => uint256) againstVotes; // votingRightId => against vote amount
}

struct VotingRule {
    uint256 minimumPending;
    uint256 maximumPending;
    uint256 minimumVotingPeriod;
    uint256 maximumVotingPeriod;
    uint256 minimumVotesForProposing;
    uint256 minimumVotes;
    address voteCounter;
}

interface IWorkersUnion {
    enum VotingState {Pending, Voting, Passed, Rejected, Executed} // Enum

    function launch() external;

    function changeVotingRule(
        uint256 minimumPendingPeriod,
        uint256 maximumPendingPeriod,
        uint256 minimumVotingPeriod,
        uint256 maximumVotingPeriod,
        uint256 minimumVotesForProposing,
        uint256 minimumVotes,
        address voteCounter
    ) external;

    function proposeTx(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 startsIn,
        uint256 votingPeriod
    ) external;

    function proposeBatchTx(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 startsIn,
        uint256 votingPeriod
    ) external;

    function vote(bytes32 txHash, bool agree) external;

    function manualVote(
        bytes32 txHash,
        uint256[] memory rightIds,
        bool agree
    ) external;

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external;

    function scheduleBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external;

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external payable;

    function executeBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external payable;

    function votingRule() external view returns (VotingRule memory);

    function getVotingStatus(bytes32 txHash)
        external
        view
        returns (VotingState);

    function getVotesFor(address account, bytes32 txHash)
        external
        view
        returns (uint256);

    function getVotesAt(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function proposals(bytes32 proposalHash)
        external
        view
        returns (
            address proposer,
            uint256 start,
            uint256 end,
            uint256 totalForVotes,
            uint256 totalAgainstVotes
        );
}