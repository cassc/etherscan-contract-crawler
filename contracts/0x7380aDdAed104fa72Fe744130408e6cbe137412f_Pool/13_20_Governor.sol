// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/IService.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IDispatcher.sol";

/// @dev Proposal module for Pool's Governance Token
abstract contract Governor {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Proposal structure
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param target Target
     * @param value ETH value
     * @param callData Call data to pass in .call() to target
     * @param startBlock Start block
     * @param endBlock End block
     * @param forVotes For votes
     * @param againstVotes Against votes
     * @param executed Is executed
     * @param state Proposal state
     * @param description Description
     * @param totalSupply Total supply
     * @param lastVoteBlock Block when last vote was cast
     * @param proposalType Proposal type
     * @param execDelay Execution delay for the proposal, blocks
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     */
    struct Proposal {
        uint256 ballotQuorumThreshold;
        uint256 ballotDecisionThreshold;
        address[] targets;
        uint256[] values;
        bytes callData;
        uint256 startBlock;
        uint256 endBlock; // startBlock + ballotLifespan
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        ProposalExecutionState state;
        string description;
        uint256 totalSupply;
        uint256 lastVoteBlock;
        IDispatcher.ProposalType proposalType;
        uint256 execDelay;
        string metaHash;
        address token;
    }

    /// @dev Proposals
    mapping(uint256 => Proposal) private _proposals;

    /// @dev For votes
    mapping(address => mapping(uint256 => uint256)) private _forVotes;

    /// @dev Against votes
    mapping(address => mapping(uint256 => uint256)) private _againstVotes;

    /// @dev Last proposal ID
    uint256 public lastProposalId;

    /// @dev Proposal state, Cancelled, Executed - unused
    enum ProposalState {
        None,
        Active,
        Failed,
        Successful,
        Executed,
        Cancelled
    }

    /// @dev Proposal execution state
    /// @dev unused - to refactor
    enum ProposalExecutionState {
        Initialized,
        Rejected,
        Accomplished,
        Cancelled
    }

    // EVENTS

    /**
     * @dev Event emitted on proposal creation
     * @param proposalId Proposal ID
     * @param quorum Quorum
     * @param targets Targets
     * @param values Values
     * @param calldatas Calldata
     * @param description Description
     */
    event ProposalCreated(
        uint256 proposalId,
        uint256 quorum,
        address[] targets,
        uint256[] values,
        bytes calldatas,
        string description
    );

    /**
     * @dev Event emitted on proposal vote cast
     * @param voter Voter address
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param support Against or for
     */
    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        bool support
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

    /**
     * @dev Event emitted on error in try/catch block
     * @param data Error data
     */
    event ErrorCaugth(bytes data);

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return proposal state
     * @param proposalId Proposal ID
     * @return ProposalState
     */
    function proposalState(uint256 proposalId)
        public
        view
        returns (ProposalState)
    {
        Proposal memory proposal = _proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.startBlock == 0) {
            return ProposalState.None;
        }

        if (proposal.state == ProposalExecutionState.Cancelled) {
            return ProposalState.Cancelled;
        }

        uint256 totalAvailableVotes = _getTotalSupply() -
            _getTotalTGEVestedTokens();
        uint256 quorumVotes = (totalAvailableVotes *
            proposal.ballotQuorumThreshold);
        uint256 totalCastVotes = proposal.forVotes + proposal.againstVotes;

        ProposalState aheadOfTimeBallotResult = aheadOfTimeBallot(totalCastVotes, quorumVotes,
                                proposal, totalAvailableVotes);
        if (aheadOfTimeBallotResult != ProposalState.None)
            return aheadOfTimeBallotResult;

        if (block.number > proposal.endBlock) {
            if (
                totalCastVotes >= quorumVotes &&
                proposal.forVotes * 10000 >=
                totalCastVotes * proposal.ballotDecisionThreshold
            ) {
                return ProposalState.Successful;
            } else return ProposalState.Failed;
        }
        return ProposalState.Active;

    }

    function aheadOfTimeBallot(
        uint256 totalCastVotes, 
        uint256 quorumVotes, 
        Proposal memory proposal, 
        uint256 totalAvailableVotes
    ) public pure returns (ProposalState) {
        uint256 decisionVotes = totalCastVotes * proposal.ballotDecisionThreshold;
        uint256 minForVotes = totalAvailableVotes * proposal.ballotDecisionThreshold;

        if (
            totalCastVotes * 10000 >= quorumVotes && // /10000 because 10000 = 100%
            proposal.forVotes * 10000 >= decisionVotes && // * 10000 because 10000 = 100%
            proposal.forVotes * 10000 >= minForVotes
        ) {
            return ProposalState.Successful;
        }
        if (
            proposal.forVotes * 10000 < decisionVotes && // * 10000 because 10000 = 100%
            (totalAvailableVotes - proposal.againstVotes) * 10000 < minForVotes
        ) {
            return ProposalState.Failed;
        }

        return ProposalState.None;
    }

    /**
     * @dev Return proposal
     * @param proposalId Proposal ID
     * @return Proposal
     */
    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    /**
     * @dev Return proposal for votes for a given user
     * @param user User address
     * @param proposalId Proposal ID
     * @return For votes
     */
    function getForVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _forVotes[user][proposalId];
    }

    /**
     * @dev Return proposal against votes for a given user
     * @param user User address
     * @param proposalId Proposal ID
     * @return Against votes
     */
    function getAgainstVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _againstVotes[user][proposalId];
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Create proposal
     * @param ballotLifespan Ballot lifespan
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param targets Targets
     * @param values Values
     * @param callData Calldata
     * @param description Description
     * @param totalSupply Total supply
     * @param execDelay Execution delay
     * @param proposalType Proposal type
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     * @return proposalId Proposal ID
     */
    function _propose(
        uint256 ballotLifespan,
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        address[] memory targets,
        uint256[] memory values,
        bytes memory callData,
        string memory description,
        uint256 totalSupply,
        uint256 execDelay,
        IDispatcher.ProposalType proposalType,
        string memory metaHash,
        address token_
    ) internal returns (uint256 proposalId) {
        proposalId = ++lastProposalId;
        _proposals[proposalId] = Proposal({
            ballotQuorumThreshold: ballotQuorumThreshold,
            ballotDecisionThreshold: ballotDecisionThreshold,
            targets: targets,
            values: values,
            callData: callData,
            startBlock: block.number,
            endBlock: block.number + ballotLifespan,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            state: ProposalExecutionState.Initialized,
            description: description,
            totalSupply: totalSupply,
            lastVoteBlock: 0,
            proposalType: proposalType,
            execDelay: execDelay,
            metaHash: metaHash,
            token: token_
        });
        _afterProposalCreated(proposalId);

        emit ProposalCreated(
            proposalId,
            ballotQuorumThreshold,
            targets,
            values,
            callData,
            description
        );
    }

    /**
     * @dev Cast vote for a proposal
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param support Against or for
     */
    function _castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) internal {
        require(
            _proposals[proposalId].endBlock > block.number,
            ExceptionsLibrary.VOTING_FINISHED
        );

        if (support) {
            _proposals[proposalId].forVotes += votes;
            _forVotes[msg.sender][proposalId] += votes;
        } else {
            _proposals[proposalId].againstVotes += votes;
            _againstVotes[msg.sender][proposalId] += votes;
        }

        _proposals[proposalId].lastVoteBlock = block.number;
        _proposals[proposalId].totalSupply = _getTotalSupply() -
            _getTotalTGEVestedTokens();

        emit VoteCast(msg.sender, proposalId, votes, support);
    }

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     * @param service Service address
     */
    function _executeBallot(
        uint256 proposalId,
        IService service
    ) internal {
        Proposal memory proposal = _proposals[proposalId];

        if (
            proposal.proposalType == IDispatcher.ProposalType.TransferETH || 
            proposal.proposalType == IDispatcher.ProposalType.TransferERC20
        ) {
            require(service.isExecutorWhitelisted(msg.sender), ExceptionsLibrary.INVALID_USER);
        }

        require(
            proposalState(proposalId) == ProposalState.Successful,
            ExceptionsLibrary.WRONG_STATE
        );
        require(
            _proposals[proposalId].state == ProposalExecutionState.Initialized,
            ExceptionsLibrary.ALREADY_EXECUTED
        );

        if (block.number >= proposal.endBlock) {
            require(block.number >= proposal.endBlock + proposal.execDelay, ExceptionsLibrary.BLOCK_DELAY);
        } else {
            require(block.number >= proposal.lastVoteBlock + proposal.execDelay, ExceptionsLibrary.BLOCK_DELAY);
        }

        _proposals[proposalId].executed = true;
        bool success = false;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
             // Give pool shareholders time to cancel bugged/hacked ballot execution
            require(
                isDelayCleared(IPool(address(this)), proposalId, i),
                ExceptionsLibrary.BLOCK_DELAY
            );
            if (proposal.proposalType != IDispatcher.ProposalType.TransferERC20) {
                (success, ) = proposal.targets[i].call{
                    value: proposal.values[i]
                }(proposal.callData);
                require(success, ExceptionsLibrary.EXECUTION_FAILED);
            } else {
                IERC20Upgradeable(proposal.token).safeTransfer(proposal.targets[i], proposal.values[i]);
            }
        }

        if (
            proposal.proposalType == IDispatcher.ProposalType.TransferETH
        ) {
            service.addEvent(
                IDispatcher.EventType.TransferETH,
                proposalId,
                proposal.metaHash
            );
        }

        if (
            proposal.proposalType == IDispatcher.ProposalType.TransferERC20
        ) {
            service.addEvent(
                IDispatcher.EventType.TransferERC20,
                proposalId,
                proposal.metaHash
            );
        }

        if (proposal.proposalType == IDispatcher.ProposalType.TGE) {
            service.addEvent(IDispatcher.EventType.TGE, proposalId, proposal.metaHash);
        }

        if (
            proposal.proposalType ==
            IDispatcher.ProposalType.GovernanceSettings
        ) {
            service.addEvent(
                IDispatcher.EventType.GovernanceSettings,
                proposalId,
                proposal.metaHash
            );
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Return: is proposal block delay cleared. Block delay is applied based on proposal type and pool governance settings.
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return Is delay cleared
     */
    function isDelayCleared(IPool pool, uint256 proposalId, uint256 index)
        public
        returns (bool)
    {
        Proposal memory proposal = _proposals[proposalId];
        uint256 assetValue = 0;

        // proposal type based delay
        uint256 delay = pool.ballotExecDelay(
            uint256(proposal.proposalType) + 1
        );

        // delay for transfer type proposals
        if (
            proposal.proposalType ==
            IDispatcher.ProposalType.TransferETH ||
            proposal.proposalType == IDispatcher.ProposalType.TransferERC20
        ) {
            address from = pool.service().secondaryAsset();
            uint256 amount = proposal.values[index];

            if (
                proposal.proposalType ==
                IDispatcher.ProposalType.TransferERC20
            ) {
                from = proposal.targets[index];
                amount = proposal.values[index];
            }

            // calculate USDT value of transfer tokens
            // Uniswap reverts if tokens are not supported.
            // In order to allow transfer of ERC20 tokens that are not supported on uniswap, we catch the revert
            // And allow the proposal token transfer to pass through
            // This is kinda vulnerable to Uniswap token/pool price/listing manipulation, perhaps this needs to be refactored some time later
            // In order to prevent executing proposals by temporary making token pair/pool not supported by uniswap (which would cause revert and allow proposal to be executed)
            try
                pool.service().uniswapQuoter().quoteExactInput(
                    abi.encodePacked(from, uint24(3000), pool.service().primaryAsset()),
                    amount
                )
            returns (uint256 v) {
                assetValue = v;
            } catch (
                bytes memory data /*lowLevelData*/
            ) {
                emit ErrorCaugth(data);
            }

            if (
                assetValue >= pool.ballotExecDelay(0) &&
                block.number <= delay + proposal.lastVoteBlock
            ) {
                return false;
            }
        }

        // delay for non transfer type proposals
        if (
            proposal.proposalType == IDispatcher.ProposalType.TGE ||
            proposal.proposalType ==
            IDispatcher.ProposalType.GovernanceSettings
        ) {
            if (block.number <= delay + proposal.lastVoteBlock) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Cancel proposal
     * @param proposalId Proposal ID
     */
    function _cancelBallot(uint256 proposalId) internal {
        require(
            proposalState(proposalId) == ProposalState.Active ||
                proposalState(proposalId) == ProposalState.Successful,
            ExceptionsLibrary.WRONG_STATE
        );

        _proposals[proposalId].state = ProposalExecutionState.Cancelled;

        emit ProposalCancelled(proposalId);
    }

    function _afterProposalCreated(uint256 proposalId) internal virtual;

    function _getTotalSupply() internal view virtual returns (uint256);

    function _getTotalTGEVestedTokens() internal view virtual returns (uint256);
}