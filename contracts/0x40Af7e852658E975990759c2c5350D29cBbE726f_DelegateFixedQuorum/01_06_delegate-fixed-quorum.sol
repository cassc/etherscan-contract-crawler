// SPDX-License-Identifier: BSD-3-Clause

/// @title Federation Delegate

import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NounsTokenLike, NounsDAOStorageV1} from "./external/nouns/governance/NounsDAOInterfaces.sol";
import "./federation.sol";

pragma solidity ^0.8.16;

contract DelegateFixedQuorum is DelegateEvents {
    /// @notice The name of this contract
    string public constant name = "federation fixed quorum";

    /// @notice the address of the vetoer
    address public vetoer;    

    /// @notice the address of the controlling DAO logic contract
    NounsDAOStorageV1 public ownerDAO;

    /// @notice the address of the token that governs the owner DAO
    NounsTokenLike public nounishToken;

    /// @notice The total number of delegate actions proposed
    uint256 public proposalCount;

    /// @notice the window in blocks that a proposal which has met quorum can be executed
    uint256 public execWindow;

    /// @notice the default quorum for all proposals
    uint256 public quorum;

    /// @notice The official record of all delegate actions ever proposed
    mapping(uint256 => DelegateAction) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    /**
     * @param nounishToken_ The address of the Nounish tokens that govern the owner DAO
     * @param ownerDAO_ The address of the external Nounish DAO
     * @param execWindow_ The window in blocks that a proposal which has met quorum can be executed
     * @param quorum_ Fixed quorum for proposal
     */
    constructor(address _vetoer, address nounishToken_, NounsDAOStorageV1 ownerDAO_, uint256 execWindow_, uint256 quorum_) {
        require(
            address(ownerDAO_) != address(0),
            "invalid owner dao address"
        );

        require(
            nounishToken_ != address(0),
            "invalid nounish NFT address"
        );

        nounishToken = NounsTokenLike(nounishToken_);
        ownerDAO = ownerDAO_;
        execWindow = execWindow_;
        vetoer = _vetoer;
        quorum = quorum_;
    }

    function _externalProposal(NounsDAOStorageV1 eDAO, uint256 ePropID) public view returns (uint256) {
        (,,,,,, uint256 ePropEndBlock,,,,,,) = eDAO.proposals(
            ePropID
        );

        return ePropEndBlock;
    }

    function _alreadyProposed(address eDAO, uint256 ePropID) public view returns (bool) {
        for (uint i=1; i <= proposalCount; i++){
            if (proposals[i].eDAO == eDAO && proposals[i].eID == ePropID) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param eDAO Target address of the external DAO executor
     * @param ePropID The ID of the proposal on the external DAO
     * @return Proposal id of internal delegate action
     */
    function propose(NounsDAOStorageV1 eDAO, uint256 ePropID) public returns (uint256) {
        require(
            nounishToken.getPriorVotes(msg.sender, block.number - 1) > 0,
            "representation required to start a vote"
        );

        require(
            address(eDAO) != address(0),
            "external DAO address is not valid"
        );

        require (
            !_alreadyProposed(address(eDAO), ePropID),
            "proposal already proposed"
        );

        // this delegate must have representation before voting can be started
        try eDAO.nouns().getPriorVotes(address(this), block.number - 1) returns (uint96 votes) {
            require(votes > 0, "delegate does not have external DAO representation");   
        } catch(bytes memory) {
            revert("checking delegate representation on external DAO failed");
        }        

        // check when external proposal ends
        uint256 ePropEndBlock;
        try this._externalProposal(eDAO, ePropID) returns (uint256 endBlock) {
            ePropEndBlock = endBlock;
        } catch(bytes memory) {
            revert(
                string.concat("invalid external proposal id: ", 
                    Strings.toString(ePropID), 
                    " for external DAO: ", 
                    Strings.toHexString(address(eDAO))
                )
            );
        }

        require(ePropEndBlock > block.number, "external proposal has already ended or does not exist");

        proposalCount++;
        DelegateAction storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.eID = ePropID;
        newProposal.eDAO = address(eDAO);
        newProposal.proposer = msg.sender;
        newProposal.quorumVotes = quorum;

        /// @notice immediately open proposal for voting
        newProposal.startBlock = block.number;
        newProposal.endBlock = ePropEndBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.executed = false;
        newProposal.vetoed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            newProposal.eDAO,
            newProposal.eID,
            newProposal.startBlock,
            newProposal.endBlock,
            newProposal.quorumVotes
        );

        return newProposal.id;
    }

    /**
     * @notice Executes a proposal if it has met quorum
     * @param proposalId The id of the proposal to execute
     * @dev This function ensures that the proposal has reached quorum through a result check
     */
    function execute(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Active,
            "proposal can only be executed if it is active"
        );

        ProposalResult r = result(proposalId);
        require(
            r != ProposalResult.Undecided,
            "proposal result cannot be undecided"
        );

        DelegateAction storage proposal = proposals[proposalId];
        proposal.executed = true;

        require(
            block.number >= proposal.endBlock-execWindow,
            "proposal can only be executed if it is within the execution window"
        );

        // untrusted external calls, don't modify any state after this point
        // support values 0=against, 1=for, 2=abstain
        INounsDAOGovernance eDAO = INounsDAOGovernance(proposal.eDAO);
        if (r == ProposalResult.For) {
            eDAO.castVote(proposal.eID, 1);
        } else if (r == ProposalResult.Against) {
            eDAO.castVote(proposal.eID, 0);
        } else if (r == ProposalResult.Abstain) {
            eDAO.castVote(proposal.eID, 2);
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Vetoes a proposal only if sender is the vetoer and the proposal has not been executed.
     * @param proposalId The id of the proposal to veto
     */
    function veto(uint256 proposalId) external {
        require(vetoer != address(0), "veto power burned");
        
        require(msg.sender == vetoer, "caller not vetoer");
        
        require(
            state(proposalId) != ProposalState.Executed,
            "cannot veto executed proposal"
        );

        DelegateAction storage proposal = proposals[proposalId];
        proposal.vetoed = true;

        emit ProposalVetoed(proposalId);
    }    

    /**
     * @notice Cast a vote for a proposal with an optional reason
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        require(
            state(proposalId) == ProposalState.Active,
            "voting is closed"
        );

        require(support <= 2, "invalid vote type");

        DelegateAction storage proposal = proposals[proposalId];

        uint96 votes = nounishToken.getPriorVotes(msg.sender, proposal.startBlock);
        require(votes > 0, "caller does not have votes");

        Receipt storage receipt = proposal.receipts[msg.sender];

        require(
            receipt.hasVoted == false,
            "already voted"
        );

        if (support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(
            msg.sender,
            proposalId,
            support,
            votes,
            reason
        );
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, "proposal not found");

        DelegateAction storage proposal = proposals[proposalId];

        if (proposal.vetoed) {
            return ProposalState.Vetoed;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.number > proposal.endBlock) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Active;
        }
    }

    /**
     * @notice Gets the result of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal result
     */
    function result(uint256 proposalId) public view returns (ProposalResult) {
        require(proposalCount >= proposalId, "invalid proposal id");

        DelegateAction storage proposal = proposals[proposalId];

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes ;
        if (totalVotes < proposal.quorumVotes) {
            return ProposalResult.Undecided;
        }

        if ((proposal.abstainVotes > proposal.forVotes) && (proposal.abstainVotes > proposal.againstVotes)) {
            return ProposalResult.Abstain;
        }

        if (proposal.againstVotes > proposal.forVotes) {
            return ProposalResult.Against;
        }

        if (proposal.forVotes > proposal.againstVotes) {
            return ProposalResult.For;
        }

        return ProposalResult.Undecided;
    }

    /**
     * @notice Changes proposal exec window
     * @dev function for updating the exec window of a proposal
     */
    function _setExecWindow(uint newExecWindow) public {
        require(msg.sender == address(ownerDAO), "only owner can change exec window");

        emit NewExecWindow(execWindow, newExecWindow);

        execWindow = newExecWindow;
    }

    /**
     * @notice Burns veto priviledges
     * @dev Vetoer function destroying veto power forever
     */
    function _burnVetoPower() public {
        require(msg.sender == vetoer, "vetoer only");
        _setVetoer(address(0));
    }

    /**
     * @notice Changes vetoer address
     * @dev Vetoer function for updating vetoer address
     */
    function _setVetoer(address newVetoer) public {
        require(msg.sender == vetoer, "vetoer only");

        emit NewVetoer(vetoer, newVetoer);

        vetoer = newVetoer;
    }
}