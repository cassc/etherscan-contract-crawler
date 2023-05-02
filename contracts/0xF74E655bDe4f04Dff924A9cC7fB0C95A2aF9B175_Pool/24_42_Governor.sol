// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/IService.sol";
import "../interfaces/IPool.sol";
import "../interfaces/governor/IGovernor.sol";
import "../interfaces/registry/IRegistry.sol";

/// @dev Proposal module for Pool's Governance Token
abstract contract Governor {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    // CONSTANTS

    /// @notice Denominator for shares (such as thresholds)
    uint256 private constant DENOM = 100 * 10**4;

    // STORAGE

    /// @dev Proposal state
    enum ProposalState {
        None,
        Active,
        Failed,
        Delayed,
        AwaitingExecution,
        Executed,
        Cancelled
    }

    /**
     * @dev Struct with proposal data related to voting and execution
     * @param startBlock Voting start block
     * @param endBlock Voting end block
     * @param availableVotes Total amount of votes participating
     * @param forVotes For votes
     * @param againstVotes Against votes
     * @param executionState Execution state
     */
    struct ProposalVotingData {
        uint256 startBlock;
        uint256 endBlock;
        uint256 availableVotes;
        uint256 forVotes;
        uint256 againstVotes;
        ProposalState executionState;
    }

    /**
     * @dev Struct with proposal data
     * @param core Proposal core data
     * @param vote Proposal voting data
     * @param meta Proposal meta data
     */
    struct Proposal {
        IGovernor.ProposalCoreData core;
        ProposalVotingData vote;
        IGovernor.ProposalMetaData meta;
    }

    /// @dev Proposals
    mapping(uint256 => Proposal) public proposals;

    enum Ballot {
        None,
        Against,
        For
    }

    /// @dev Voter's ballots
    mapping(address => mapping(uint256 => Ballot)) public ballots;

    /// @dev Last proposal ID
    uint256 public lastProposalId;

    // EVENTS

    /**
     * @dev Event emitted on proposal creation
     * @param proposalId Proposal ID
     * @param core Proposal core data
     * @param meta Proposal meta data
     */
    event ProposalCreated(
        uint256 proposalId,
        IGovernor.ProposalCoreData core,
        IGovernor.ProposalMetaData meta
    );

    /**
     * @dev Event emitted on proposal vote cast
     * @param voter Voter address
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param ballot Ballot (against or for)
     */
    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        Ballot ballot
    );

    /**
     * @dev Event emitted on proposal execution
     * @param proposalId Proposal ID
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Event emitted on proposal cancellation
     * @param proposalId Proposal ID
     */
    event ProposalCancelled(uint256 proposalId);

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev This method returns the outcome for a specific proposal in the pool, a proposal is approved if the quorum and decision threshold values are reached before the voting duration period has elapsed
     * @param proposalId Proposal ID
     * @return ProposalState
     */
    function proposalState(uint256 proposalId)
        public
        view
        returns (ProposalState)
    {
        Proposal memory proposal = proposals[proposalId];

        if (proposal.vote.startBlock == 0) {
            return ProposalState.None;
        }

        // If proposal executed, cancelled or simply not started, return immediately
        if (
            proposal.vote.executionState == ProposalState.Executed ||
            proposal.vote.executionState == ProposalState.Cancelled
        ) {
            return proposal.vote.executionState;
        }
        if (
            proposal.vote.startBlock > 0 &&
            block.number < proposal.vote.startBlock
        ) {
            return ProposalState.Active;
        }
        uint256 availableVotesForStartBlock = _getBlockTotalVotes(
            proposal.vote.startBlock - 1
        );
        uint256 castVotes = proposal.vote.forVotes + proposal.vote.againstVotes;

        if (block.number >= proposal.vote.endBlock) {
            // Proposal fails if quorum threshold is not reached
            if (
                !shareReached(
                    castVotes,
                    availableVotesForStartBlock,
                    proposal.core.quorumThreshold
                )
            ) {
                return ProposalState.Failed;
            }
            // Proposal fails if decision threshold is not reched
            if (
                !shareReached(
                    proposal.vote.forVotes,
                    castVotes,
                    proposal.core.decisionThreshold
                )
            ) {
                return ProposalState.Failed;
            }
            // Otherwise succeeds, check for delay
            if (
                block.number >=
                proposal.vote.endBlock + proposal.core.executionDelay
            ) {
                return ProposalState.AwaitingExecution;
            } else {
                return ProposalState.Delayed;
            }
        } else {
            return ProposalState.Active;
        }
    }

    /**
     * @dev Return voting result for a given account and proposal
     * @param account Account address
     * @param proposalId Proposal ID
     * @return ballot Vote type
     * @return votes Number of votes cast
     */
    function getBallot(address account, uint256 proposalId)
        public
        view
        returns (Ballot ballot, uint256 votes)
    {
        if (proposals[proposalId].vote.startBlock - 1 < block.number)
            return (
                ballots[account][proposalId],
                _getPastVotes(
                    account,
                    proposals[proposalId].vote.startBlock - 1
                )
            );
        else
            return (
                ballots[account][proposalId],
                _getPastVotes(account, block.number - 1)
            );
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Creating a proposal and assigning it a unique identifier to store in the list of proposals in the Governor contract.
     * @param core Proposal core data
     * @param meta Proposal meta data
     * @param votingDuration Voting duration in blocks
     */
    function _propose(
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta,
        uint256 votingDuration,
        uint256 votingStartDelay
    ) internal returns (uint256 proposalId) {
        // Increment ID counter
        proposalId = ++lastProposalId;

        // Create new proposal
        proposals[proposalId] = Proposal({
            core: core,
            vote: ProposalVotingData({
                startBlock: block.number + votingStartDelay,
                endBlock: block.number + votingStartDelay + votingDuration,
                availableVotes: 0,
                forVotes: 0,
                againstVotes: 0,
                executionState: ProposalState.None
            }),
            meta: meta
        });

        // Call creation hook
        _afterProposalCreated(proposalId);

        // Emit event
        emit ProposalCreated(proposalId, core, meta);
    }

    /**
     * @dev A method through which participating addresses vote to approve or decline any proposal, this methos can only be used only for active proposals, and the probability of an early end of voting is taken into account, after each call of this method, an assessment is made of whether the remaining free votes can change the course of voting, if not, then the proposal closes ahead of schedule.
     * @param proposalId Proposal ID
     * @param support Against or for
     */
    function _castVote(uint256 proposalId, bool support) internal {
        // Check that voting exists, is started and not finished
        require(
            proposals[proposalId].vote.startBlock != 0,
            ExceptionsLibrary.NOT_LAUNCHED
        );
        require(
            proposals[proposalId].vote.startBlock <= block.number,
            ExceptionsLibrary.NOT_LAUNCHED
        );
        require(
            proposals[proposalId].vote.endBlock > block.number,
            ExceptionsLibrary.VOTING_FINISHED
        );
        require(
            ballots[msg.sender][proposalId] == Ballot.None,
            ExceptionsLibrary.ALREADY_VOTED
        );

        // Get number of votes
        uint256 votes = _getPastVotes(
            msg.sender,
            proposals[proposalId].vote.startBlock - 1
        );

        require(votes > 0, ExceptionsLibrary.ZERO_VOTES);

        // Account votes
        if (support) {
            proposals[proposalId].vote.forVotes += votes;
            ballots[msg.sender][proposalId] = Ballot.For;
        } else {
            proposals[proposalId].vote.againstVotes += votes;
            ballots[msg.sender][proposalId] = Ballot.Against;
        }

        // Check for voting early end
        _checkProposalVotingEarlyEnd(proposalId);

        // Emit event
        emit VoteCast(
            msg.sender,
            proposalId,
            votes,
            support ? Ballot.For : Ballot.Against
        );
    }

    /**
     * @dev Performance of the proposal with checking its status. Only the Awaiting Execution of the proposals can be executed.
     * @param proposalId Proposal ID
     * @param service Service address
     */
    function _executeProposal(uint256 proposalId, IService service) internal {
        // Check state
        require(
            proposalState(proposalId) == ProposalState.AwaitingExecution,
            ExceptionsLibrary.WRONG_STATE
        );

        // Mark as executed
        proposals[proposalId].vote.executionState = ProposalState.Executed;

        // Execute actions
        Proposal memory proposal = proposals[proposalId];
        for (uint256 i = 0; i < proposal.core.targets.length; i++) {
            if (proposal.core.callDatas[i].length == 0) {
                payable(proposal.core.targets[i]).sendValue(
                    proposal.core.values[i]
                );
            } else {
                proposal.core.targets[i].functionCallWithValue(
                    proposal.core.callDatas[i],
                    proposal.core.values[i]
                );
            }
        }

        // Add event to service
        service.addEvent(
            proposal.meta.proposalType,
            proposalId,
            proposal.meta.metaHash
        );

        // Emit contract event
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev The substitution of proposals, both active and those that have a positive voting result, but have not yet been executed.
     * @param proposalId Proposal ID
     */
    function _cancelProposal(uint256 proposalId) internal {
        // Check proposal state
        ProposalState state = proposalState(proposalId);
        require(
            state == ProposalState.Active ||
                state == ProposalState.Delayed ||
                state == ProposalState.AwaitingExecution,
            ExceptionsLibrary.WRONG_STATE
        );

        // Mark proposal as cancelled
        proposals[proposalId].vote.executionState = ProposalState.Cancelled;

        // Emit event
        emit ProposalCancelled(proposalId);
    }

    /**
     * @dev The method checks whether it is possible to end the voting early with the result fixed. If a quorum was reached and so many votes were cast in favor that even if all other available votes were cast against, or if so many votes were cast against that it could not affect the result of the vote, this function will change set the end block of the proposal to the current block
     * @param proposalId Proposal ID
     */
    function _checkProposalVotingEarlyEnd(uint256 proposalId) internal {
        // Get values
        Proposal memory proposal = proposals[proposalId];
        uint256 availableVotesForStartBlock = _getBlockTotalVotes(
            proposal.vote.startBlock - 1
        );
        uint256 castVotes = proposal.vote.forVotes + proposal.vote.againstVotes;
        uint256 extraVotes = availableVotesForStartBlock - castVotes;

        // Check if quorum is reached
        if (
            !shareReached(
                castVotes,
                availableVotesForStartBlock,
                proposal.core.quorumThreshold
            )
        ) {
            return;
        }

        // Check for early guaranteed result
        if (
            !shareOvercome(
                proposal.vote.forVotes + extraVotes,
                availableVotesForStartBlock,
                proposal.core.decisionThreshold
            ) ||
            shareReached(
                proposal.vote.forVotes,
                availableVotesForStartBlock,
                proposal.core.decisionThreshold
            )
        ) {
            // Mark voting as finished
            proposals[proposalId].vote.endBlock = block.number;
        }
    }

    // INTERNAL PURE FUNCTIONS

    /**
     * @dev Checks if `amount` divided by `total` exceeds `share`
     * @param amount Amount numerator
     * @param total Amount denominator
     * @param share Share numerator
     */
    function shareReached(
        uint256 amount,
        uint256 total,
        uint256 share
    ) internal pure returns (bool) {
        return amount * DENOM >= share * total;
    }

    /**
     * @dev Checks if `amount` divided by `total` overcomes `share`
     * @param amount Amount numerator
     * @param total Amount denominator
     * @param share Share numerator
     */
    function shareOvercome(
        uint256 amount,
        uint256 total,
        uint256 share
    ) internal pure returns (bool) {
        return amount * DENOM > share * total;
    }

    // ABSTRACT FUNCTIONS

    /**
     * @dev Hook called after a proposal is created
     * @param proposalId Proposal ID
     */
    function _afterProposalCreated(uint256 proposalId) internal virtual;

    /**
     * @dev Function that returns the total amount of votes in the pool in block
     * @param blocknumber block number
     * @return Total amount of votes
     */
    function _getBlockTotalVotes(uint256 blocknumber)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev Function that returns the amount of votes for a client adrress at any given block
     * @param account Account's address
     * @param blockNumber Block number
     * @return Account's votes at given block
     */
    function _getPastVotes(address account, uint256 blockNumber)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev Function that set last ProposalId for a client address
     * @param proposer Proposer's address
     * @param proposalId Proposal id
     */
    function _setLastProposalIdForAddress(address proposer, uint256 proposalId)
        internal
        virtual;
}