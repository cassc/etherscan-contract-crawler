// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGovernorBravo} from "./IGovernorBravo.sol";

// IGovernorBravo extended with castRefundableVote logic and custom ProposalCondensed struct
interface INounsDAOV2 is IGovernorBravo {
    struct ProposalCondensed {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The number of votes needed to create a proposal at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 proposalThreshold;
        /// @notice The minimum number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 quorumVotes;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
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
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice The total supply at the time of proposal creation
        uint256 totalSupply;
        /// @notice The block at which this proposal was created
        uint256 creationBlock;
    }

    function proposals(uint256 proposalId) external view returns (ProposalCondensed memory);

    function castRefundableVote(uint256 proposalId, uint8 support) external;

    function castRefundableVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) external;
}