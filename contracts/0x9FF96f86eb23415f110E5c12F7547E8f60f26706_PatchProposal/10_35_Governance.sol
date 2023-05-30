// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "torn-token/contracts/ENS.sol";
import "torn-token/contracts/TORN.sol";
import "./Delegation.sol";
import "./Configuration.sol";

contract Governance is Initializable, Configuration, Delegation, EnsResolve {
    using SafeMath for uint256;
    /// @notice Possible states that a proposal may be in

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
        // Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // Whether or not the voter supports the proposal
        bool support;
        // The number of votes the voter had, which were cast
        uint256 votes;
    }

    /// @notice The official record of all proposals ever proposed
    Proposal[] public proposals;
    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;
    /// @notice Timestamp when a user can withdraw tokens
    mapping(address => uint256) public canWithdrawAfter;

    TORN public torn;

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        address target,
        uint256 startTime,
        uint256 endTime,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    event Voted(uint256 indexed proposalId, address indexed voter, bool indexed support, uint256 votes);

    /// @notice An event emitted when a proposal has been executed
    event ProposalExecuted(uint256 indexed proposalId);

    /// @notice Makes this instance inoperable to prevent selfdestruct attack
    /// Proxy will still be able to properly initialize its storage
    constructor() public initializer {
        torn = TORN(0x000000000000000000000000000000000000dEaD);
        _initializeConfiguration();
    }

    function initialize(bytes32 _torn) public initializer {
        torn = TORN(resolve(_torn));
        // Create a dummy proposal so that indexes start from 1
        proposals.push(
            Proposal({
                proposer: address(this),
                target: 0x000000000000000000000000000000000000dEaD,
                startTime: 0,
                endTime: 0,
                forVotes: 0,
                againstVotes: 0,
                executed: true,
                extended: false
            })
        );
        _initializeConfiguration();
    }

    function lock(address owner, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
    {
        torn.permit(owner, address(this), amount, deadline, v, r, s);
        _transferTokens(owner, amount);
    }

    function lockWithApproval(uint256 amount) public virtual {
        _transferTokens(msg.sender, amount);
    }

    function unlock(uint256 amount) public virtual {
        require(getBlockTimestamp() > canWithdrawAfter[msg.sender], "Governance: tokens are locked");
        lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(amount, "Governance: insufficient balance");
        require(torn.transfer(msg.sender, amount), "TORN: transfer failed");
    }

    function propose(address target, string memory description) external returns (uint256) {
        return _propose(msg.sender, target, description);
    }

    /**
     * @notice Propose implementation
     * @param proposer proposer address
     * @param target smart contact address that will be executed as result of voting
     * @param description description of the proposal
     * @return the new proposal id
     */
    function _propose(address proposer, address target, string memory description)
        internal
        virtual
        override(Delegation)
        returns (uint256)
    {
        uint256 votingPower = lockedBalance[proposer];
        require(
            votingPower >= PROPOSAL_THRESHOLD, "Governance::propose: proposer votes below proposal threshold"
        );
        // target should be a contract
        require(Address.isContract(target), "Governance::propose: not a contract");

        uint256 latestProposalId = latestProposalIds[proposer];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(
                proposersLatestProposalState != ProposalState.Active
                    && proposersLatestProposalState != ProposalState.Pending,
                "Governance::propose: one live proposal per proposer, found an already active proposal"
            );
        }

        uint256 startTime = getBlockTimestamp().add(VOTING_DELAY);
        uint256 endTime = startTime.add(VOTING_PERIOD);

        Proposal memory newProposal = Proposal({
            proposer: proposer,
            target: target,
            startTime: startTime,
            endTime: endTime,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            extended: false
        });

        proposals.push(newProposal);
        uint256 proposalId = proposalCount();
        latestProposalIds[newProposal.proposer] = proposalId;

        _lockTokens(proposer, endTime.add(VOTE_EXTEND_TIME).add(EXECUTION_EXPIRATION).add(EXECUTION_DELAY));
        emit ProposalCreated(proposalId, proposer, target, startTime, endTime, description);
        return proposalId;
    }

    function execute(uint256 proposalId) public payable virtual {
        require(
            state(proposalId) == ProposalState.AwaitingExecution,
            "Governance::execute: invalid proposal state"
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        address target = proposal.target;
        require(Address.isContract(target), "Governance::execute: not a contract");
        (bool success, bytes memory data) = target.delegatecall(abi.encodeWithSignature("executeProposal()"));
        if (!success) {
            if (data.length > 0) {
                revert(string(data));
            } else {
                revert("Proposal execution failed");
            }
        }

        emit ProposalExecuted(proposalId);
    }

    function castVote(uint256 proposalId, bool support) external virtual {
        _castVote(msg.sender, proposalId, support);
    }

    function _castVote(address voter, uint256 proposalId, bool support) internal override(Delegation) {
        require(state(proposalId) == ProposalState.Active, "Governance::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        bool beforeVotingState = proposal.forVotes <= proposal.againstVotes;
        uint256 votes = lockedBalance[voter];
        require(votes > 0, "Governance: balance is 0");
        if (receipt.hasVoted) {
            if (receipt.support) {
                proposal.forVotes = proposal.forVotes.sub(receipt.votes);
            } else {
                proposal.againstVotes = proposal.againstVotes.sub(receipt.votes);
            }
        }

        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        if (!proposal.extended && proposal.endTime.sub(getBlockTimestamp()) < CLOSING_PERIOD) {
            bool afterVotingState = proposal.forVotes <= proposal.againstVotes;
            if (beforeVotingState != afterVotingState) {
                proposal.extended = true;
                proposal.endTime = proposal.endTime.add(VOTE_EXTEND_TIME);
            }
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;
        _lockTokens(
            voter, proposal.endTime.add(VOTE_EXTEND_TIME).add(EXECUTION_EXPIRATION).add(EXECUTION_DELAY)
        );
        emit Voted(proposalId, voter, support, votes);
    }

    function _lockTokens(address owner, uint256 timestamp) internal {
        if (timestamp > canWithdrawAfter[owner]) {
            canWithdrawAfter[owner] = timestamp;
        }
    }

    function _transferTokens(address owner, uint256 amount) internal virtual {
        require(torn.transferFrom(owner, address(this), amount), "TORN: transferFrom failed");
        lockedBalance[owner] = lockedBalance[owner].add(amount);
    }

    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId <= proposalCount() && proposalId > 0, "Governance::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (getBlockTimestamp() <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (getBlockTimestamp() <= proposal.endTime) {
            return ProposalState.Active;
        } else if (
            proposal.forVotes <= proposal.againstVotes
                || proposal.forVotes + proposal.againstVotes < QUORUM_VOTES
        ) {
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (getBlockTimestamp() >= proposal.endTime.add(EXECUTION_DELAY).add(EXECUTION_EXPIRATION)) {
            return ProposalState.Expired;
        } else if (getBlockTimestamp() >= proposal.endTime.add(EXECUTION_DELAY)) {
            return ProposalState.AwaitingExecution;
        } else {
            return ProposalState.Timelocked;
        }
    }

    function proposalCount() public view returns (uint256) {
        return proposals.length - 1;
    }

    function getBlockTimestamp() internal view virtual returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}