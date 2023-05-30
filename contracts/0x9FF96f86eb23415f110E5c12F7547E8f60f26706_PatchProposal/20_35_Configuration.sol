// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract Configuration {
    /// @notice Time delay between proposal vote completion and its execution
    uint256 public EXECUTION_DELAY;
    /// @notice Time before a passed proposal is considered expired
    uint256 public EXECUTION_EXPIRATION;
    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint256 public QUORUM_VOTES;
    /// @notice The number of votes required in order for a voter to become a proposer
    uint256 public PROPOSAL_THRESHOLD;
    /// @notice The delay before voting on a proposal may take place, once proposed
    /// It is needed to prevent reorg attacks that replace the proposal
    uint256 public VOTING_DELAY;
    /// @notice The duration of voting on a proposal
    uint256 public VOTING_PERIOD;
    /// @notice If the outcome of a proposal changes during CLOSING_PERIOD, the vote will be extended by VOTE_EXTEND_TIME (no more than once)
    uint256 public CLOSING_PERIOD;
    /// @notice If the outcome of a proposal changes during CLOSING_PERIOD, the vote will be extended by VOTE_EXTEND_TIME (no more than once)
    uint256 public VOTE_EXTEND_TIME;

    modifier onlySelf() {
        require(msg.sender == address(this), "Governance: unauthorized");
        _;
    }

    function _initializeConfiguration() internal {
        EXECUTION_DELAY = 2 days;
        EXECUTION_EXPIRATION = 3 days;
        QUORUM_VOTES = 25_000e18; // 0.25% of TORN
        PROPOSAL_THRESHOLD = 1000e18; // 0.01% of TORN
        VOTING_DELAY = 75 seconds;
        VOTING_PERIOD = 3 days;
        CLOSING_PERIOD = 1 hours;
        VOTE_EXTEND_TIME = 6 hours;
    }

    function setExecutionDelay(uint256 executionDelay) external onlySelf {
        EXECUTION_DELAY = executionDelay;
    }

    function setExecutionExpiration(uint256 executionExpiration) external onlySelf {
        EXECUTION_EXPIRATION = executionExpiration;
    }

    function setQuorumVotes(uint256 quorumVotes) external onlySelf {
        QUORUM_VOTES = quorumVotes;
    }

    function setProposalThreshold(uint256 proposalThreshold) external onlySelf {
        PROPOSAL_THRESHOLD = proposalThreshold;
    }

    function setVotingDelay(uint256 votingDelay) external onlySelf {
        VOTING_DELAY = votingDelay;
    }

    function setVotingPeriod(uint256 votingPeriod) external onlySelf {
        VOTING_PERIOD = votingPeriod;
    }

    function setClosingPeriod(uint256 closingPeriod) external onlySelf {
        CLOSING_PERIOD = closingPeriod;
    }

    function setVoteExtendTime(uint256 voteExtendTime) external onlySelf {
        // VOTE_EXTEND_TIME should be less EXECUTION_DELAY to prevent double voting
        require(voteExtendTime < EXECUTION_DELAY, "Governance: incorrect voteExtendTime");
        VOTE_EXTEND_TIME = voteExtendTime;
    }
}