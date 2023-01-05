//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
                                                      ...:--==***#@%%-
                                             ..:  -*@@@@@@@@@@@@@#*:  
                               -:::-=+*#%@@@@@@*[email protected]@@@@@@@@@@#+=:     
           .::---:.         +#@@@@@@@@@@@@@%*+-. [email protected]@@@@@+..           
    .-+*%@@@@@@@@@@@#-     [email protected]@@@@@@@@@%#*=:.    :@@@@@@@#%@@@@@%:     
 =#@@@@@@@@@@@@@@@@@@@%.   %@@@@@@-..           *@@@@@@@@@@@@%*.      
[email protected]@@@@@@@@#*+=--=#@@@@@%  [email protected]@@@@@%*#%@@@%*=-.. [email protected]@@@@@@%%*+=:         
 :*@@@@@@*       [email protected]@@@@@.*@@@@@@@@@@@@*+-      =%@@@@%                
  [email protected]@@@@@.       *@@@@@%:@@@@@@*==-:.          [email protected]@@@@:                
 [email protected]@@@@@=      [email protected]@@@@@%.*@@@@@=   ..::--=+*=+*[email protected]@@@=                 
 #@@@@@*    [email protected]@@@@@@* [email protected]@@@@#%%@@@@@@@@#+:.  =#@@=                  
 @@@@@%   :*@@@@@@@*:  .#@@@@@@@@@@@@@%#:       ---                   
:@@@@%. -%@@@@@@@+.     [email protected]@@@@%#*+=:.                                 
[email protected]@@%=*@@@@@@@*:        =*:                                           
:*#+%@@@@%*=.                                                         
 :+##*=:.

*/

import {Auth} from "./lib/Auth.sol";
import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";
import {IERC721} from "openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title
 * Definitely Revoke v1
 *
 * @author
 * DEF DAO
 *
 * @notice
 * A contract to revoke memberships based on a simple voting mechanism.
 */
contract DefinitelyRevoke is Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice The main membership contract
    address public memberships;

    /* PROPOSALS ----------------------------------------------------------- */

    /// @dev Allows a member to propose another membership be revoked
    struct Proposal {
        address initiator;
        uint8 approvalCount;
        bool addToDenyList;
        address[] voters;
    }

    /// @notice Keeps track of revoke membership proposals by token id
    mapping(uint256 => Proposal) public proposals;

    /* VOTING -------------------------------------------------------------- */

    /// @dev Voting configuration for reaching quorum on proposals
    struct VotingConfig {
        uint64 minQuorum;
        uint64 maxVotes;
    }

    /// @notice The voting configuration for this contract
    VotingConfig public votingConfig;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    event ProposalCreated(uint256 indexed id, address indexed initiator, bool addToDenyList);
    event ProposalCancelled(uint256 indexed id, address indexed initiator);
    event ProposalApproved(uint256 indexed id, address indexed initiator);
    event ProposalDenied(uint256 indexed id, address indexed initiator);

    /* ------------------------------------------------------------------------
       E R R O R S    
    ------------------------------------------------------------------------ */

    error NotDefMember();
    error AlreadyDefMember();

    error ProposalNotFound();
    error ProposalInProgress();
    error ProposalEnded();
    error CannotCreateProposalForSelf();

    error AlreadyVoted();
    error NotProposalInitiator();

    /* ------------------------------------------------------------------------
       M O D I F I E R S    
    ------------------------------------------------------------------------ */

    /// @dev Reverts if `msg.sender` is not a member
    modifier onlyDefMember() {
        if (!(IERC721(memberships).balanceOf(msg.sender) < 1)) revert NotDefMember();
        _;
    }

    /// @dev Reverts if `to` is already a member
    modifier whenNotDefMember(address to) {
        if (IERC721(memberships).balanceOf(to) > 0) revert AlreadyDefMember();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ Contract owner address
     * @param memberships_ The main membership contract
     * @param minQuorum_ The min number of votes to approve a proposal
     * @param maxVotes_ The max number of votes a proposal can have
     */
    constructor(
        address owner_,
        address memberships_,
        uint64 minQuorum_,
        uint64 maxVotes_
    ) Auth(owner_) {
        memberships = memberships_;
        votingConfig = VotingConfig(minQuorum_, maxVotes_);
    }

    /* ------------------------------------------------------------------------
       R E V O K I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Allows a member to propose revoking the membership of another member
     *
     * @dev
     * Reverts if:
     *   - `msg.sender` currently owns the token they are attempting to revoke
     *   - there is a proposal in progress for `id`
     *
     * @param id The ID of the membership to revoke
     * @param addToDenyList If the owner of the revoked token should be denied future membership
     */
    function newProposal(uint256 id, bool addToDenyList) external onlyDefMember {
        address currentOwner = IERC721(memberships).ownerOf(id);
        Proposal storage proposal = proposals[id];

        // Prevent the current owner from creating a proposal
        if (msg.sender == currentOwner) revert CannotCreateProposalForSelf();

        // Can't update an existing proposal, it must be cancelled first since it may
        // have votes in progress
        if (proposal.initiator != address(0)) revert ProposalInProgress();

        // Init the new proposal
        proposal.initiator = msg.sender;
        proposal.addToDenyList = addToDenyList;
        emit ProposalCreated(id, proposal.initiator, addToDenyList);
    }

    /**
     * @notice
     * Allows the member who created the proposal to cancel it
     *
     * @dev
     * Reverts if:
     *   - `msg.sender` did not initiate the proposal
     *
     * @param id The ID of the proposal to cancel (the membership token id)
     */
    function cancelProposal(uint256 id) external onlyDefMember {
        Proposal storage proposal = proposals[id];
        if (proposal.initiator != msg.sender) revert NotProposalInitiator();
        delete proposals[id];
        emit ProposalCancelled(id, proposal.initiator);
    }

    /**
     * @notice
     * Allows a member to vote on a revoke membership proposal
     *
     * @dev
     * If the proposal reaches quorum, the last voter will burn the membership and
     * optionally add the owner to the deny list if it was defined in the proposal
     *
     * Reverts if:
     *   - the proposal doesn't exist
     *   - the proposal has ended
     *   - `msg.sender` has already voted
     *
     * @param id The ID of the proposal to cancel (the membership token id)
     */
    function vote(uint256 id, bool inFavor) external onlyDefMember {
        VotingConfig memory config = votingConfig;
        Proposal storage proposal = proposals[id];

        if (proposal.initiator == address(0)) revert ProposalNotFound();
        if (proposal.approvalCount == config.minQuorum || proposal.voters.length == config.maxVotes)
            revert ProposalEnded();

        // Check if this account has voted on this proposal already
        for (uint256 a = 0; a < proposal.voters.length; a++) {
            if (proposal.voters[a] == msg.sender) revert AlreadyVoted();
        }

        proposal.voters.push(msg.sender);

        // Remove an approval if the member says no
        if (!inFavor && proposal.approvalCount > 0) --proposal.approvalCount;

        // Add an approval if the member says yes
        if (inFavor) ++proposal.approvalCount;

        // Last vote has been reached but min approvals hasn't, then deny the proposal
        if (
            proposal.voters.length == config.maxVotes && proposal.approvalCount < config.minQuorum
        ) {
            emit ProposalDenied(id, proposal.initiator);
        }

        // If the proposal reaches quorum, revoke from the memberships contract
        if (proposal.approvalCount == config.minQuorum) {
            emit ProposalApproved(id, proposal.initiator);
            IDefinitelyMemberships(memberships).revokeMembership(id, proposal.addToDenyList);
        }
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Admin function to update the voting configuration
     *
     * @param minQuorum_ The min number of votes to approve a proposal
     * @param maxVotes_ The max number of votes a proposal can have
     */
    function setVotingConfig(uint64 minQuorum_, uint64 maxVotes_) external onlyOwnerOrAdmin {
        votingConfig = VotingConfig(minQuorum_, maxVotes_);
    }
}