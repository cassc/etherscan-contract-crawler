// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 _______  _______  _______  _        _        _______  _          _______           _        _        _______
(  ____ \(  ____ )(  ___  )( (    /|| \    /\(  ____ \( (    /|  (  ____ )|\     /|( (    /|| \    /\(  ____ \
| (    \/| (    )|| (   ) ||  \  ( ||  \  / /| (    \/|  \  ( |  | (    )|| )   ( ||  \  ( ||  \  / /| (    \/
| (__    | (____)|| (___) ||   \ | ||  (_/ / | (__    |   \ | |  | (____)|| |   | ||   \ | ||  (_/ / | (_____
|  __)   |     __)|  ___  || (\ \) ||   _ (  |  __)   | (\ \) |  |  _____)| |   | || (\ \) ||   _ (  (_____  )
| (      | (\ (   | (   ) || | \   ||  ( \ \ | (      | | \   |  | (      | |   | || | \   ||  ( \ \       ) |
| )      | ) \ \__| )   ( || )  \  ||  /  \ \| (____/\| )  \  |  | )      | (___) || )  \  ||  /  \ \/\____) |
|/       |/   \__/|/     \||/    )_)|_/    \/(_______/|/    )_)  |/       (_______)|/    )_)|_/    \/\_______)

*/

import "./interfaces/IGovernance.sol";
import "./interfaces/IExecutor.sol";
import "./interfaces/IStaking.sol";
import "./utils/Admin.sol";
import "./utils/Refundable.sol";
import "./utils/SafeCast.sol";

/// @title FrankenDAO Governance
/// @author Zach Obront & Zakk Fleischmann
/// @notice Users use their staked FrankenPunks and FrankenMonsters to make & vote on governance proposals
/** @dev Loosely forked from NounsDAOLogicV1.sol (0xa43afe317985726e4e194eb061af77fbcb43f944) with following major modifications:
- add gas refunding for voting and creating proposals
- pack proposal struct into fewer storage slots 
- track votes, proposals created, and proposal passed by user for community score calculation
- track votes, proposals created, and proposal passed across all users counting towards community voting power
- removed tempProposal from the proposal creation process
- added a verification step for new proposals to confirm they passed Snapshot pre-governance
- adjusted roles and permissions
- added an array to track Active Proposals and a clear() function to remove them 
- removed the ability to pass a reason along with a vote, and to vote by EIP-712 signature
- allow the contract to receive Ether (for gas refunds)
 */
contract Governance is IGovernance, Admin, Refundable {
    using SafeCast for uint;

    /// @notice The name of this contract
    string public constant name = "FrankenDAO";

    /// @notice The address of staked the Franken tokens
    IStaking public staking;

    //////////////////////////
    //// Voting Constants ////
    //////////////////////////

    /// @notice The min setable voting delay 
    /// @dev votingDelay is the time between a proposal being created and voting opening
    uint256 public constant MIN_VOTING_DELAY = 1 hours;

    /// @notice The max setable voting delay
    /// @dev votingDelay is the time between a proposal being created and voting opening
    uint256 public constant MAX_VOTING_DELAY = 1 weeks;

    /// @notice The minimum setable voting period 
    /// @dev votingPeriod is the time that voting is open for
    uint256 public constant MIN_VOTING_PERIOD = 1 days; 

    /// @notice The max setable voting period 
    /// @dev votingPeriod is the time that voting is open for
    uint256 public constant MAX_VOTING_PERIOD = 14 days;

    /// @notice The minimum setable proposal threshold
    /// @dev proposalThreshold is the minimum percentage of votes that a user must have to create a proposal
    uint256 public constant MIN_PROPOSAL_THRESHOLD_BPS = 1; // 1 basis point or 0.01%

    /// @notice The maximum setable proposal threshold
    /// @dev proposalThreshold is the minimum percentage of votes that a user must have to create a proposal
    uint256 public constant MAX_PROPOSAL_THRESHOLD_BPS = 1_000; // 1,000 basis points or 10%

    /// @notice The minimum setable quorum votes basis points
    /// @dev quorumVotesBPS is the minimum percentage of YES votes that must be cast on a proposal for it to succeed
    uint256 public constant MIN_QUORUM_VOTES_BPS = 200; // 200 basis points or 2%

    /// @notice The maximum setable quorum votes basis points
    /// @dev quorumVotesBPS is the minimum percentage of YES votes that must be cast on a proposal for it to succeed
    uint256 public constant MAX_QUORUM_VOTES_BPS = 2_000; // 2,000 basis points or 20%

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant PROPOSAL_MAX_OPERATIONS = 10; // 10 actions

    ///////////////////////////
    //// Voting Parameters ////
    ///////////////////////////

    /// @notice The delay before voting on a proposal may take place, once proposed, in seconds.
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in seconds.
    uint256 public votingPeriod;

    /// @notice The basis point number of votes required in order for a voter to become a proposer. 
    uint256 public proposalThresholdBPS;

    /// @notice The basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. 
    uint256 public quorumVotesBPS;

    /// @notice Whether or not gas is refunded for casting votes.
    bool public votingRefund;

    /// @notice Whether or not gas is refunded for submitting proposals.
    bool public proposalRefund;

    //////////////////
    //// Proposal ////
    //////////////////

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    /// @notice Propsals that are currently verified, but have not been canceled, vetoed, or queued
    /** @dev Admins (or anyone else) will regularly clear out proposals that have been defeated 
             by calling clear() to keep gas costs of iterating through this array low  */
    uint256[] public activeProposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    /// @notice Users who have been banned from creating proposals
    mapping(address => bool) public bannedProposers;

    /// @notice The number of votes, verified proposals, and passed proposals for each user
    mapping(address => CommunityScoreData) public userCommunityScoreData;

    /// @notice The total number of votes, verified proposals, and passed proposals actively contributing to total community voting power
    /** @dev Users only get community voting power if they currently have token voting power (ie have staked, undelegated tokens 
            or are delegated to). These totals adjust as users stake, undelegate, or delegate to ensure they only reflect the current 
            total community score. Therefore, these totals will not equal the sum of the totals in the userCommunityScoreData mapping. */
    /// @dev This is used to calculate the total voting power of the entire system, so that we can calculate thresholds from BPS.
    CommunityScoreData public totalCommunityScoreData;


    /// @notice Initialize the contract during proxy setup
    /// @param _executor The address of the FrankenDAO Executor
    /// @param _staking The address of the staked FrankenPunks tokens
    /// @param _founders The address of the founder multisig
    /// @param _council The address of the council multisig
    /// @param _votingPeriod The initial voting period (time voting is open for)
    /// @param _votingDelay The initial voting delay (time between proposal creation and voting opening)
    /// @param _proposalThresholdBPS The initial threshold to create a proposal (in basis points)
    /// @param _quorumVotesBPS The initial threshold of quorum votes needed (in basis points)
    function initialize(
        address _staking,
        address _executor,
        address _founders,
        address _council,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _proposalThresholdBPS,
        uint256 _quorumVotesBPS
    ) public {
        // Check whether this contract has already been initialized.
        if (address(executor) != address(0)) revert AlreadyInitialized();
        if (address(_executor) == address(0)) revert ZeroAddress();

        if (_votingDelay < MIN_VOTING_DELAY || _votingDelay > MAX_VOTING_DELAY) revert ParameterOutOfBounds();
        if (_votingPeriod < MIN_VOTING_PERIOD || _votingPeriod > MAX_VOTING_PERIOD) revert ParameterOutOfBounds();
        if (_proposalThresholdBPS < MIN_PROPOSAL_THRESHOLD_BPS || _proposalThresholdBPS > MAX_PROPOSAL_THRESHOLD_BPS) revert ParameterOutOfBounds();
        if (_quorumVotesBPS < MIN_QUORUM_VOTES_BPS || _quorumVotesBPS > MAX_QUORUM_VOTES_BPS) revert ParameterOutOfBounds();

        executor = IExecutor(_executor);
        founders = _founders;
        council = _council;
        staking = IStaking(_staking);

        votingRefund = true;
        proposalRefund = true;

        emit VotingDelaySet(0, votingDelay = _votingDelay);
        emit VotingPeriodSet(0, votingPeriod = _votingPeriod);
        emit ProposalThresholdBPSSet(0, proposalThresholdBPS = _proposalThresholdBPS);
        emit QuorumVotesBPSSet(0, quorumVotesBPS = _quorumVotesBPS);
    }

    ///////////////////
    //// Modifiers ////
    ///////////////////

    modifier cancelable(uint _proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        if (
            // Proposals that are executed, canceled, or vetoed have already been removed from
            // ActiveProposals array and the Executor queue.
            state(_proposalId) == ProposalState.Executed ||
            state(_proposalId) == ProposalState.Canceled ||
            state(_proposalId) == ProposalState.Vetoed ||

            // Proposals that are Defeated or Expired should be cleared instead, to preserve their state.
            state(_proposalId) == ProposalState.Defeated ||
            state(_proposalId) == ProposalState.Expired
        ) revert InvalidStatus();

        _;
    }

    ///////////////
    //// Views ////
    ///////////////

    /// @notice Gets actions of a proposal
    /// @param _proposalId the id of the proposal
    /// @return targets Array of addresses that the Executor will call if the proposal passes
    /// @return values Array of values (i.e. msg.value) that Executor will call if the proposal passes
    /// @return signatures Array of function signatures that the Executor will call if the proposal passes
    /// @return calldatas Array of calldata that the Executor will call if the proposal passes
    function getActions(uint256 _proposalId) external view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /// @notice Gets the data of a proposal
    /// @param _proposalId the id of the proposal
    /// @return id the id of the proposal
    /// @return proposer the address of the proposer
    /// @return quorumVotes the number of YES votes needed for the proposal to pass
    function getProposalData(uint256 _proposalId) public view returns (uint256, address, uint256) {
        Proposal storage p = proposals[_proposalId];
        return (p.id, p.proposer, p.quorumVotes);
    }

    /// @notice Gets the status of a proposal
    /// @param _proposalId the id of the proposal
    /// @return verified has the team verified the proposal?
    /// @return canceled has the proposal been canceled?
    /// @return vetoed has the proposal been vetoed?
    /// @return executed has the proposal been executed?
    function getProposalStatus(uint256 _proposalId) public view returns (bool, bool, bool, bool) {
        Proposal storage p = proposals[_proposalId];
        return (p.verified, p.canceled, p.vetoed, p.executed);
    }

    /// @notice Gets the voting status of a proposal
    /// @param _proposalId the id of the proposal
    /// @return forVotes the number of votes in favor of the proposal
    /// @return againstVotes the number of votes against the proposal
    /// @return abstainVotes the number of abstain votes
    function getProposalVotes(uint256 _proposalId) public view returns (uint256, uint256, uint256) {
        Proposal storage p = proposals[_proposalId];
        return (p.forVotes, p.againstVotes, p.abstainVotes);
    }

    /// @notice Gets a list of all Active Proposals (created, but not queued, canceled, vetoed, or cleared)
    /// @return activeProposals the list of proposal ids
    function getActiveProposals() public view returns (uint256[] memory) {
        return activeProposals;
    }

    
    /// @notice Gets the receipt for a voter on a given proposal
    /// @param _proposalId the id of proposal
    /// @param _voter The address of the voter
    /// @return The voting receipt (hasVoted, support, votes)
    function getReceipt(uint256 _proposalId, address _voter) external view returns (Receipt memory) {
        return proposals[_proposalId].receipts[_voter];
    }

    /// @notice Gets the state of a proposal
    /// @param _proposalId The id of the proposal
    /// @return Proposal state
    function state(uint256 _proposalId) public view returns (ProposalState) {
        if (_proposalId > proposalCount) revert InvalidId();
        Proposal storage proposal = proposals[_proposalId];

        // If the proposal has been vetoed, it should always return Vetoed.
        if (proposal.vetoed) {
            return ProposalState.Vetoed;

        // If the proposal isn't verified by the time it ends, it's Canceled.
        } else if (proposal.canceled || (!proposal.verified && block.timestamp > proposal.endTime)) {
            return ProposalState.Canceled;

        // If it's unverified at any time before end time, or if it is verified but is before start time, it's Pending.
        }  else if (block.timestamp < proposal.startTime || !proposal.verified) {
            return ProposalState.Pending;
        
        // If it's verified and after start time but before end time, it's Active.
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;

        // If this is the case, it means it was verified and it's after the end time. 
        // The YES votes must be greater than the NO votes, and greater than or equal to quorumVotes to pass.
        // If it doesn't meet these criteria, it's Defeated.
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quorumVotes) {
            return ProposalState.Defeated;

        // If this is the case, the proposal passed, but it hasn't been queued yet, so it's Succeeded.
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;

        // execute() has been called, so the transaction has been run and the proposal is Executed.
        } else if (proposal.executed) {
            return ProposalState.Executed;

        // If execute() hasn't been run and we're GRACE_PERIOD after the eta, it's Expired.
        } else if (block.timestamp >= proposal.eta + executor.GRACE_PERIOD()) {
            return ProposalState.Expired;
        
        // Otherwise, it's queued, unexecuted, and within the GRACE_PERIOD, so we're Queued.
        } else {
            return ProposalState.Queued;
        }
    }

    /// @notice Current proposal threshold based on the voting power of the system
    /// @dev This incorporates the totals of both token voting power and community voting power
    function proposalThreshold() public view returns (uint256) {
        return bps2Uint(proposalThresholdBPS, staking.getTotalVotingPower());
    }

    /// @notice Current quorum threshold based on the voting power of the system
    /// @dev This incorporates the totals of both token voting power and community voting power
    function quorumVotes() public view returns (uint256) {
        return bps2Uint(quorumVotesBPS, staking.getTotalVotingPower());
    }

    ///////////////////
    //// Proposals ////
    ///////////////////

    /// @notice Function used to propose a new proposal
    /// @param _targets Target addresses for proposal calls
    /// @param _values Eth values for proposal calls
    /// @param _signatures Function signatures for proposal calls
    /// @param _calldatas Calldatas for proposal calls
    /// @param _description String description of the proposal
    /// @return Proposal id of new proposal
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) public returns (uint256) {
        uint proposalId;

        // Refunds gas if proposalRefund is true
        if (proposalRefund) {
            uint256 startGas = gasleft();
            proposalId = _propose(_targets, _values, _signatures, _calldatas, _description);
            _refundGas(startGas);
        } else {
            proposalId = _propose(_targets, _values, _signatures, _calldatas, _description);
        }
        return proposalId;
    }

    /// @notice Function used to propose a new proposal
    /// @param _targets Target addresses for proposal calls
    /// @param _values Eth values for proposal calls
    /// @param _signatures Function signatures for proposal calls
    /// @param _calldatas Calldatas for proposal calls
    /// @param _description String description of the proposal
    /// @return Proposal id of new proposal
    function _propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) internal returns (uint256) {
        // Confirm the user hasn't been banned
        if (bannedProposers[msg.sender]) revert NotAuthorized();

        // Confirm the proposer meets the proposalThreshold
        uint votesNeededToPropose = proposalThreshold();
        if (staking.getVotes(msg.sender) < votesNeededToPropose) revert NotEligible();

        // Validate the proposal's actions
        if (_targets.length == 0) revert InvalidProposal();
        if (_targets.length > PROPOSAL_MAX_OPERATIONS) revert InvalidProposal();
        if (
            _targets.length != _values.length ||
            _targets.length != _signatures.length ||
            _targets.length != _calldatas.length
        ) revert InvalidProposal();

        // Ensure the proposer doesn't already have an active or pending proposal
        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            if (
                proposersLatestProposalState == ProposalState.Active || 
                proposersLatestProposalState == ProposalState.Pending
            ) revert NotEligible();
        }
        
        // Create a new proposal in storage, and fill it with the correct data
        uint newProposalId = ++proposalCount;
        Proposal storage newProposal = proposals[newProposalId];

        // All non-array values in the Proposal struct are packed into 2 storage slots:
        // Slot 1: id (96) + proposer (address, 160)
        // Slot 2: quorumVotes (24), eta (32), startTime (32), endTime (32), forVotes (24), 
        //         againstVotes (24), canceled (8), vetoed (8), executed (8), verified (8)
        
        // All times are stored as uint32s, which takes us through the year 2106 (we can upgrade then :))
        // All votes are stored as uint24s with lots of buffer, since max votes in system is < 4 million
        // (10k punks * (max 50 token VP + max ~100 community VP) + 10k monsters * (max 25 token VP + max ~100 community VP))
        
        newProposal.id = newProposalId.toUint96();
        newProposal.proposer = msg.sender;
        newProposal.targets = _targets;
        newProposal.values = _values;
        newProposal.signatures = _signatures;
        newProposal.calldatas = _calldatas;
        newProposal.quorumVotes = quorumVotes().toUint24();
        newProposal.startTime = (block.timestamp + votingDelay).toUint32();
        newProposal.endTime = (block.timestamp + votingDelay + votingPeriod).toUint32();
        
        // Other values are set automatically:
        //  - forVotes, againstVotes, and abstainVotes = 0
        //  - verified, canceled, executed, and vetoed = false
        //  - eta = 0

        latestProposalIds[newProposal.proposer] = newProposalId;
        activeProposals.push(newProposalId);

        emit ProposalCreated(
            newProposalId,
            msg.sender,
            _targets,
            _values,
            _signatures,
            _calldatas,
            newProposal.startTime,
            newProposal.endTime,
            newProposal.quorumVotes,
            _description
        );

        return newProposalId;
    }

    /// @notice Function for verifying a proposal
    /// @param _proposalId Id of the proposal to verify
    /// @dev This is intended to confirm that the proposal got through Snapshot pre-governance
    /// @dev This doesn't add any additional centralization risk, as the team already has veto power
    function verifyProposal(uint _proposalId) external onlyVerifierOrAdmins {
        // Can only verify proposals that are currently in the Pending state
        if (state(_proposalId) != ProposalState.Pending) revert InvalidStatus();

        Proposal storage proposal = proposals[_proposalId];
        
        if (proposal.verified) revert InvalidStatus();
        proposal.verified = true;

        // If a proposal was valid, we are ready to award the community voting power bonuses to the proposer
        ++userCommunityScoreData[proposal.proposer].proposalsCreated;
        
        // We don't need to check whether the proposer is accruing community voting power because
        // they needed that voting power to propose, and once they have an Active Proposal, their
        // tokens are locked from delegating and unstaking.
        ++totalCommunityScoreData.proposalsCreated;
    }

    /////////////////
    //// Execute ////
    /////////////////

    /// @notice Queues a proposal of state succeeded
    /// @param _proposalId The id of the proposal to queue
    function queue(uint256 _proposalId) external {
        // Succeeded means we're past the endTime, yes votes outweigh no votes, and quorum threshold is met
        if(state(_proposalId) != ProposalState.Succeeded) revert InvalidStatus();

        Proposal storage proposal = proposals[_proposalId];

        // Set the ETA (time for execution) to the soonest time based on the Executor's delay
        uint256 eta = block.timestamp + executor.DELAY();
        proposal.eta = eta.toUint32();

        // Queue separate transactions for each action in the proposal
        uint numTargets = proposal.targets.length;
        for (uint256 i = 0; i < numTargets; i++) {
            executor.queueTransaction(i, proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }

        // If a proposal is queued, we are ready to award the community voting power bonuses to the proposer
        ++userCommunityScoreData[proposal.proposer].proposalsPassed;

        // We don't need to check whether the proposer is accruing community voting power because
        // they needed that voting power to propose, and once they have an Active Proposal, their
        // tokens are locked from delegating and unstaking.
        ++totalCommunityScoreData.proposalsPassed;

        // Remove the proposal from the Active Proposals array
        _removeFromActiveProposals(_proposalId);

        emit ProposalQueued(_proposalId, eta);
    }

    /// @notice Executes a queued proposal if eta has passed
    /// @param _proposalId The id of the proposal to execute
    function execute(uint256 _proposalId) external {
        // Queued means the proposal is passed, queued, and within the grace period.
        if (state(_proposalId) != ProposalState.Queued) revert InvalidStatus();

        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;

        // Separate transactions were queued for each action in the proposal, so execute each separately
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            executor.executeTransaction(
                i, proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta
            );
        }

        emit ProposalExecuted(_proposalId);
    }

    ////////////////////////////////
    //// Cancel / Veto Proposal ////
    ////////////////////////////////

    /// @notice Vetoes a proposal 
    /// @param _proposalId The id of the proposal to veto
    /// @dev This allows the founder or council multisig to veto a malicious proposal
    function veto(uint256 _proposalId) external cancelable(_proposalId) onlyAdmins {
        Proposal storage proposal = proposals[_proposalId];

        // If the proposal is queued or executed, remove it from the Executor's queuedTransactions mapping
        // Otherwise, remove it from the Active Proposals array
        _removeTransactionWithQueuedOrExpiredCheck(proposal);

        // Update the vetoed flag so the proposal's state is Vetoed
        proposal.vetoed = true;

        // Remove Community Voting Power someone might have earned from creating
        // the proposal
        if (proposal.verified) {
            --userCommunityScoreData[proposal.proposer].proposalsCreated;
            --totalCommunityScoreData.proposalsCreated;
        }

        if (state(_proposalId) == ProposalState.Queued) {
            --userCommunityScoreData[proposal.proposer].proposalsPassed;
            --totalCommunityScoreData.proposalsPassed;
        }

        emit ProposalVetoed(_proposalId);
    }

    /// @notice Cancels a proposal
    /// @param _proposalId The id of the proposal to cancel
    function cancel(uint256 _proposalId) external cancelable(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        // Proposals can be canceled if proposer themselves decide to cancel the proposal (at any time before execution)
        // Nouns allows anyone to cancel if proposer falls below threshold, but because tokens are locked, this isn't possible
        if (msg.sender != proposal.proposer) revert NotEligible();

        // If the proposal is queued or executed, remove it from the Executor's queuedTransactions mapping
        // Otherwise, remove it from the Active Proposals array
        _removeTransactionWithQueuedOrExpiredCheck(proposal);

        // Set the canceled flag to true to change the status to Canceled
        proposal.canceled = true;   

        emit ProposalCanceled(_proposalId);
    }

    /// @notice clear the proposal from the ActiveProposals array or the Executor's queuedTransactions
    /// @param _proposalId The id of the proposal to clear
    function clear(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        // This function can only be called in three situations:
        // 1. EXPIRED: The proposal was queued but the grace period has passed (removes it from Executor's 
        //    queuedTransactions). We use this instead of using cancel() so Expired state is preserved.
        // 2. DEFEATED: The proposal is over and was not passed (removes it from ActiveProposals array).
        //    We use this instead of using cancel() so Defeated state is preserved.
        // 3. UNVERIFIED AFTER END TIME (CANCELED): The proposal remained unverified through the endTime and is 
        //    now considered canceled (removes it from ActiveProposals array). We use this because cancel() is 
        //    not allowed to be called on canceled proposals, but this situation is a special case where the 
        //    proposal still needs to be removed from the ActiveProposals array.
        if (
            state(_proposalId) != ProposalState.Expired &&
            state(_proposalId) != ProposalState.Defeated && 
            (proposal.verified || block.timestamp <= proposal.endTime)
        ) revert NotEligible();

        // If the proposal is Expired, remove it from the Executor's queuedTransactions mapping
        // If the proposal is Defeated or Canceled, remove it from the Active Proposals array
        _removeTransactionWithQueuedOrExpiredCheck(proposal);

        emit ProposalCanceled(_proposalId);
    }

    ////////////////
    //// Voting ////
    ////////////////

    /// @notice Cast a vote for a proposal
    /// @param _proposalId The id of the proposal to vote on
    /// @param _support The support value for the vote (0=against, 1=for, 2=abstain)
    function castVote(uint256 _proposalId, uint8 _support) external {
        // Refunds gas if votingRefund is true
        if (votingRefund) {
            uint256 startGas = gasleft();
            uint votes = _castVote(msg.sender, _proposalId, _support);
            emit VoteCast( msg.sender, _proposalId, _support, votes);
            _refundGas(startGas);
        } else {
            uint votes = _castVote(msg.sender, _proposalId, _support);
            emit VoteCast( msg.sender, _proposalId, _support, votes);
        }
    }

    /// @notice Internal function that caries out voting logic
    /// @param _voter The voter that is casting their vote
    /// @param _proposalId The id of the proposal to vote on
    /// @param _support The support value for the vote (0=against, 1=for, 2=abstain)
    /// @return The number of votes cast
    function _castVote(address _voter, uint256 _proposalId, uint8 _support) internal returns (uint) {
        // Only Active proposals can be voted on
        if (state(_proposalId) != ProposalState.Active) revert InvalidStatus();
        
        // Only valid values for _support are 0 (against), 1 (for), and 2 (abstain)
        if (_support > 2) revert InvalidInput();

        Proposal storage proposal = proposals[_proposalId];

        // If the voter has already voted, revert        
        Receipt storage receipt = proposal.receipts[_voter];
        if (receipt.hasVoted) revert AlreadyVoted();

        // Calculate the number of votes a user is able to cast
        // This takes into account delegation and community voting power
        uint24 votes = (staking.getVotes(_voter)).toUint24();

        if (votes == 0) revert NotEligible();

        // Update the proposal's total voting records based on the votes
        if (_support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (_support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (_support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        // Update the user's receipt for this proposal
        receipt.hasVoted = true;
        receipt.support = _support;
        receipt.votes = votes;

        // Make these updates after the vote so it doesn't impact voting power for this vote.
        ++totalCommunityScoreData.votes;

        // We can update the total community voting power with no check because if you can vote, 
        // it means you have votes so you haven't delegated.
        ++userCommunityScoreData[_voter].votes;

        return votes;
    }


    /////////////////
    //// Helpers ////
    /////////////////
    
    /// @notice Calculates a fixed value given a BPS value and a number to calculate against
    /// @dev For example, if _bps is 5000, it means 50% of _number
    /// @dev Used to calculate the proposalThreshold or quorumThreshold at a given point in time
    function bps2Uint(uint256 _bps, uint256 _number) internal pure returns (uint256) {
        return (_number * _bps) / 10000;
    }

    /// @notice Removes a proposal from the ActiveProposals array or the Executor's queuedTransactions mapping
    /// @param _proposal The proposal to remove
    function _removeTransactionWithQueuedOrExpiredCheck(Proposal storage _proposal) internal {
        if (
            state(_proposal.id) == ProposalState.Queued || 
            state(_proposal.id) == ProposalState.Expired
        ) {
            for (uint256 i = 0; i < _proposal.targets.length; i++) {
                executor.cancelTransaction(
                    i,
                    _proposal.targets[i],
                    _proposal.values[i],
                    _proposal.signatures[i],
                    _proposal.calldatas[i],
                    _proposal.eta
                );
            }
        } else {
            _removeFromActiveProposals(_proposal.id);
        }
    }

    /// @notice Removes a proposal from the ActiveProposals array
    /// @param _id The id of the proposal to remove
    /// @dev uses swap and pop to find the proposal, swap it with the final index, and pop the final index off
    function _removeFromActiveProposals(uint256 _id) private {
        uint256 index;
        uint[] memory actives = activeProposals;

        bool found = false;
        for (uint256 i = 0; i < actives.length; i++) {
            if (actives[i] == _id) {
                found = true;
                index = i;
                break;
            }
        }

        // This is important because otherwise, if the proposal is not found, it will remove the first index
        // There shouldn't be any ways to call this with an ID that isn't in the array, but this is here for extra safety
        if (!found) revert NotInActiveProposals();

        activeProposals[index] = activeProposals[actives.length - 1];
        activeProposals.pop();
    }
    
    /// @notice Passes in new values for the total community score data
    /// @param _votes The total number of votes users have cast that are accruing towards community scores
    /// @param _againstVotes The number of proposals created that are accruing towards community scores
    /// @param _forVotes The number of proposals passed that are accruing towards community scores
    /** @dev This is used by the staking contract to update these values when users stake, unstake, delegate, 
        so that we are able to calculate total community score that equals the sum of individual community scores,
        since these actions can move their scores to 0 and back. */
    function updateTotalCommunityScoreData(uint64 _votes, uint64 _proposalsCreated, uint64 _proposalsPassed) external {
        if (msg.sender != address(staking)) revert NotAuthorized();

        totalCommunityScoreData.proposalsCreated = _proposalsCreated;
        totalCommunityScoreData.proposalsPassed = _proposalsPassed;
        totalCommunityScoreData.votes = _votes;

        emit TotalCommunityScoreDataUpdated(_proposalsCreated, _proposalsPassed, _votes);
    }

    ///////////////
    //// Admin ////
    ///////////////

    /// @notice Turn on or off gas refunds for proposing and voting
    /// @param _votingRefund Should refunds for voting be on (true) or off (false)?
    /// @param _proposalRefund Should refunds for proposing be on (true) or off (false)?
    function setRefunds(bool _votingRefund, bool _proposalRefund) external onlyExecutor {
        
        emit RefundSet(false, votingRefund, _votingRefund);
        emit RefundSet(true, proposalRefund, _proposalRefund);
        
        votingRefund = _votingRefund;
        proposalRefund = _proposalRefund;
    }

    /// @notice Admin function for setting the voting delay
    /// @param _newVotingDelay new voting delay, in seconds
    function setVotingDelay(uint256 _newVotingDelay) external onlyExecutor {
        if (_newVotingDelay < MIN_VOTING_DELAY || _newVotingDelay > MAX_VOTING_DELAY) revert ParameterOutOfBounds();

        emit VotingDelaySet(votingDelay, _newVotingDelay);

        votingDelay = _newVotingDelay;
    }

    /// @notice Admin function for setting the voting period
    /// @param _newVotingPeriod new voting period, in seconds
    function setVotingPeriod(uint256 _newVotingPeriod) external onlyExecutor {
        if (_newVotingPeriod < MIN_VOTING_PERIOD || _newVotingPeriod > MAX_VOTING_PERIOD) revert ParameterOutOfBounds();

        emit VotingPeriodSet(votingPeriod, _newVotingPeriod);

        votingPeriod = _newVotingPeriod;        
    }

    /// @notice Admin function for setting the proposal threshold basis points
    /// @param _newProposalThresholdBPS new proposal threshold
    /** @dev This function can be called by the multisigs or by governance, to ensure
        it can be decreased in the event that governance isn't able to hit the threshold. */
    function setProposalThresholdBPS(uint256 _newProposalThresholdBPS) external onlyExecutorOrAdmins {
        if (_newProposalThresholdBPS < MIN_PROPOSAL_THRESHOLD_BPS || _newProposalThresholdBPS > MAX_PROPOSAL_THRESHOLD_BPS) revert ParameterOutOfBounds();
        
        emit ProposalThresholdBPSSet(proposalThresholdBPS, _newProposalThresholdBPS);
        
        proposalThresholdBPS = _newProposalThresholdBPS;
    }

    /// @notice Admin function for setting the quorum votes basis points
    /// @param _newQuorumVotesBPS new proposal threshold
    /** @dev This function can be called by the multisigs or by governance, to ensure
        it can be decreased in the event that governance isn't able to hit the threshold. */
    function setQuorumVotesBPS(uint256 _newQuorumVotesBPS) external onlyExecutorOrAdmins {
        if (_newQuorumVotesBPS < MIN_QUORUM_VOTES_BPS || _newQuorumVotesBPS > MAX_QUORUM_VOTES_BPS) revert ParameterOutOfBounds();

        emit QuorumVotesBPSSet(quorumVotesBPS, _newQuorumVotesBPS);
        
        quorumVotesBPS = _newQuorumVotesBPS;
    }

    /// @notice Admin function to ban a user from submitting new proposals
    /// @param _proposer The user to ban
    /// @param _banned Should the user be banned (true) or unbanned (false)?
    /// @dev This function is used if a delegate tries to create constant proposals to prevent undelegation
    function banProposer(address _proposer, bool _banned) external onlyExecutorOrAdmins {
        bannedProposers[_proposer] = _banned;
    }

    /// @notice Upgrade the Staking contract to a new address
    /// @param _newStaking Address of the new Staking contract
    /// @dev Since upgrades are only allowed by governance, this is only callable by Executor
    function setStakingAddress(IStaking _newStaking) external onlyExecutor {
        try _newStaking.isFrankenPunksStakingContract() returns (bool isStaking) {
            if (!isStaking) revert NotStakingContract();
        } catch {
            revert NotStakingContract();
        }

        staking = _newStaking;

        emit NewStakingContract(address(_newStaking));
    }

    /// @notice Contract can receive ETH (will be used to pay for gas refunds)
    receive() external payable {}

    /// @notice Contract can receive ETH (will be used to pay for gas refunds)
    fallback() external payable {}
}