// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Staking } from "./Staking.sol";
import { Delegator } from "./Delegator.sol";

/**
 * @title Voting
 * @author Railgun Contributors
 * @notice Governance contract for railgun, handles voting.
 */
contract Voting {
  // Time offsets from publish time, offset times are relative to voteCallTime
  uint256 public constant SPONSOR_WINDOW = 30 days;
  uint256 public constant VOTING_START_OFFSET = 2 days; // Should be > interval size of staking snapshots
  uint256 public constant VOTING_YAY_END_OFFSET = 5 days;
  uint256 public constant VOTING_NAY_END_OFFSET = 6 days;
  uint256 public constant EXECUTION_START_OFFSET = 7 days;
  uint256 public constant EXECUTION_END_OFFSET = 14 days;
  uint256 public constant SPONSOR_LOCKOUT_TIME = 7 days;

  // Threshold constants
  uint256 public constant QUORUM = 2000000e18; // 2 million, 18 decimal places
  uint256 public constant PROPOSAL_SPONSOR_THRESHOLD = 500000e18; // 500 thousand, 18 decimal places

  // Proposal has been created
  event Proposal(uint256 indexed id, address indexed proposer);

  // Proposal has been sponsored
  event Sponsorship(uint256 indexed id, address indexed sponsor, uint256 amount);

  // Proposal has been unsponsored
  event SponsorshipRevocation(uint256 indexed id, address indexed sponsor, uint256 amount);

  // Proposal vote called
  event VoteCall(uint256 indexed id);

  // Vote cast on proposal
  event VoteCast(uint256 indexed id, address indexed voter, bool affirmative, uint256 votes);

  // Proposal executed
  event Execution(uint256 indexed id);

  // Proposal executed
  event VoteKeySet(address indexed account, address votingKey);

  // Errors
  error ExecutionFailed(uint256 index, bytes data);

  // Function call
  struct Call {
    address callContract;
    bytes data;
    uint256 value;
  }

  // Governance proposals
  struct ProposalStruct {
    // Execution status
    bool executed;

    // Proposal Data
    address proposer;
    string proposalDocument; // IPFS hash
    Call[] actions;

    // Event timestamps
    uint256 publishTime;
    uint256 voteCallTime; // If vote call time is 0, proposal hasn't gone to vote

    // Sponsorship info
    uint256 sponsorship;
    mapping(address => uint256) sponsors;

    // Vote data
    // Amount of voting power used for accounts, used for fractional voting from contracts
    mapping(address => uint256) voted;
    uint256 yayVotes;
    uint256 nayVotes;

    // Staking snapshots
    uint256 sponsorInterval;
    uint256 votingInterval;
  }

  // Proposals id => proposal data
  ProposalStruct[] public proposals;

  // Voting keys
  mapping(address => address) public votingKey;

  // Last sponsored proposal data
  struct LastSponsored {
    uint256 lastSponsorTime;
    uint256 proposalID;
  }
  mapping(address => LastSponsored) public lastSponsored;

  /* solhint-disable var-name-mixedcase */
  Staking public immutable STAKING_CONTRACT;
  Delegator public immutable DELEGATOR_CONTRACT;
  /* solhint-enable var-name-mixedcase */

  // Only voting key modifier
  modifier onlyVotingKey(address _account) {
    // Only voting key or main key can call
    require(
      msg.sender == _account || msg.sender == votingKey[_account],
      "Voting: Caller not authorized"
    );

    _;
  }

  /**
   * @notice Sets governance token ID and delegator contract
   */

  constructor(Staking _stakingContract, Delegator _delegator) {
    STAKING_CONTRACT = _stakingContract;
    DELEGATOR_CONTRACT = _delegator;
  }

  /**
   * @notice Gets length of proposals array
   * @return length
   */

  function proposalsLength() external view returns (uint256) {
    return proposals.length;
  }

  /**
   * @notice Gets actions from proposal document
   * @dev Gets actions from proposal as nested arrays won't be returned on public getter
   * @param _id - Proposal to get actions of
   * @return actions
   */

  function getActions(uint256 _id) external view returns (Call[] memory) {
    return proposals[_id].actions;
  }

  /**
   * @notice Gets sponsor amount an account has given to a proposal
   * @dev Gets actions from proposal as mappings wont be returned on public getter
   * @param _id - Proposal to get sponsor amount of
   * @param _account - Account to get sponsor amount for
   * @return sponsor amount
   */

  function getSponsored(uint256 _id, address _account) external view returns (uint256) {
    return proposals[_id].sponsors[_account];
  }

  /**
   * @notice Gets votes cast by an account on a particular proposal
   * @dev Gets votes from proposal as mappings wont be returned on public getter
   * @param _id - Proposal to get votes for
   * @param _account - Account to get votes for
   * @return votes amount
   */

  function getVotes(uint256 _id, address _account) external view returns (uint256) {
    return proposals[_id].voted[_account];
  }


  /**
   * @notice Sets voting key for account
   * @param _votingKey - voting key address
   */
  function setVotingKey(address _votingKey) external {
    votingKey[msg.sender] = _votingKey;
    emit VoteKeySet(msg.sender, _votingKey);
  }

  /**
   * @notice Creates governance proposal
   * @param _proposalDocument - IPFS multihash of proposal document
   * @param _actions - actions to take
   */

  function createProposal(string calldata _proposalDocument, Call[] calldata _actions) external returns (uint256) {
    // Don't allow proposals with no actions
    require(_actions.length > 0, "Voting: No actions specified");

    uint256 proposalID = proposals.length;

    ProposalStruct storage proposal = proposals.push();

    // Store proposer
    proposal.proposer = msg.sender;

    // Store proposal document
    proposal.proposalDocument = _proposalDocument;

    // Store published time
    proposal.publishTime = block.timestamp;

    // Store sponsor voting snapshot interval
    proposal.sponsorInterval = STAKING_CONTRACT.currentInterval();

    // Loop over actions and copy manually as solidity doesn't support copying structs
    for (uint256 i = 0; i < _actions.length; i++) {
      proposal.actions.push(Call(
        _actions[i].callContract,
        _actions[i].data,
        _actions[i].value
      ));
    }

    // Emit event
    emit Proposal(proposalID, msg.sender);

    return proposalID;
  }

  /**
   * @notice Sponsor proposal
   * @param _id - id of proposal to sponsor
   * @param _amount - amount to sponsor with
   * @param _account - account to vote with
   * @param _hint - hint for snapshot search
   */

  function sponsorProposal(uint256 _id, uint256 _amount, address _account, uint256 _hint) external onlyVotingKey(_account) {
    // Prevent proposal spam
    require(
      lastSponsored[_account].proposalID == _id
      || block.timestamp - lastSponsored[_account].lastSponsorTime > 7 days,
      "Voting: Can only sponsor one proposal per week"
    );

    ProposalStruct storage proposal = proposals[_id];

    // Check proposal hasn't already gone to vote
    require(proposal.voteCallTime == 0, "Voting: Gone to vote");

    // Check proposal is still in sponsor window
    require(block.timestamp < proposal.publishTime + SPONSOR_WINDOW, "Voting: Sponsoring window passed");

    // Set last sponsored info
    lastSponsored[_account].proposalID = _id;
    lastSponsored[_account].lastSponsorTime = block.timestamp;

    // Get address sponsor voting power
    Staking.AccountSnapshot memory snapshot = STAKING_CONTRACT.accountSnapshotAt(
      _account,
      proposal.sponsorInterval,
      _hint
    );

    // Can't sponsor with more than voting power
    require(proposal.sponsors[_account] + _amount <= snapshot.votingPower, "Voting: Not enough voting power");

    // Update address sponsorship amount on proposal
    proposal.sponsors[_account] += _amount;

    // Update sponsor total
    proposal.sponsorship += _amount;

    // Emit event
    emit Sponsorship(_id, _account, _amount);
  }

  /**
   * @notice Unsponsor proposal
   * @param _id - id of proposal to sponsor
   * @param _account - account to vote with
   * @param _amount - amount to sponsor with
   */

  function unsponsorProposal(uint256 _id, uint256 _amount, address _account) external onlyVotingKey(_account) {
    ProposalStruct storage proposal = proposals[_id];

    // Check proposal hasn't already gone to vote
    require(proposal.voteCallTime == 0, "Voting: Gone to vote");

    // Check proposal is still in sponsor window
    require(block.timestamp < proposal.publishTime + SPONSOR_WINDOW, "Voting: Sponsoring window passed");

    // Can't unsponsor more than sponsored
    require(_amount <= proposal.sponsors[_account], "Voting: Amount greater than sponsored");

    // Update address sponsorship amount on proposal
    proposal.sponsors[_account] -= _amount;

    // Update sponsor total
    proposal.sponsorship -= _amount;

    // Emit event
    emit SponsorshipRevocation(_id, _account, _amount);
  }

  /**
   * @notice Call vote
   * @param _id - id of proposal to call to vote
   */

  function callVote(uint256 _id) external {
    ProposalStruct storage proposal = proposals[_id];

    // Check proposal hasn't exceeded sponsor window
    require(block.timestamp < proposal.publishTime + SPONSOR_WINDOW, "Voting: Sponsoring window passed");

    // Check proposal hasn't already gone to vote
    require(proposal.voteCallTime == 0, "Voting: Proposal already gone to vote");

    // Proposal must meet sponsorship threshold
    require(proposal.sponsorship >= PROPOSAL_SPONSOR_THRESHOLD, "Voting: Sponsor threshold not met");

    // Log vote time (also marks proposal as ready to vote)
    proposal.voteCallTime = block.timestamp;

    // Log governance token snapshot interval
    // VOTING_START_OFFSET must be greater than snapshot interval of governance token for this to work correctly
    proposal.votingInterval = STAKING_CONTRACT.currentInterval();

    // Emit event
    emit VoteCall(_id);
  }

  /**
   * @notice Vote on proposal
   * @param _id - id of proposal to call to vote
   * @param _amount - amount of voting power to allocate
   * @param _affirmative - whether to vote yay (true) or nay (false) on this proposal
   * @param _account - account to vote with
   * @param _hint - hint for snapshot search
   */

  function vote(uint256 _id, uint256 _amount, bool _affirmative, address _account, uint256 _hint) external onlyVotingKey(_account) {
    ProposalStruct storage proposal = proposals[_id];

    // Check vote has been called
    require(proposal.voteCallTime > 0, "Voting: Vote hasn't been called for this proposal");

    // Check Voting window has opened
    require(block.timestamp > proposal.voteCallTime + VOTING_START_OFFSET, "Voting: Voting window hasn't opened");

    // Check voting window hasn't closed (voting window length conditional on )
    if(_affirmative) {
      require(block.timestamp < proposal.voteCallTime + VOTING_YAY_END_OFFSET, "Voting: Affirmative voting window has closed");
    } else {
      require(block.timestamp < proposal.voteCallTime + VOTING_NAY_END_OFFSET, "Voting: Negative voting window has closed");
    }

    // Get address voting power
    Staking.AccountSnapshot memory snapshot = STAKING_CONTRACT.accountSnapshotAt(
      _account,
      proposal.votingInterval,
      _hint
    );

    // Check address isn't voting with more voting power than it has
    require(proposal.voted[_account] + _amount <= snapshot.votingPower, "Voting: Not enough voting power to cast this vote");

    // Update account voted amount
    proposal.voted[_account] += _amount;

    // Update voting totals
    if (_affirmative) {
      proposal.yayVotes += _amount;
    } else {
      proposal.nayVotes += _amount;
    }

    // Emit event
    emit VoteCast(_id, _account, _affirmative, _amount);
  }

  /**
   * @notice Execute proposal
   * @param _id - id of proposal to execute
   */

  function executeProposal(uint256 _id) external {
    ProposalStruct storage proposal = proposals[_id];
  
    // Check proposal has been called to vote
    require(proposal.voteCallTime > 0, "Voting: Vote hasn't been called for this proposal");

    // Check quorum has been reached
    require(proposal.yayVotes >= QUORUM, "Voting: Quorum hasn't been reached");

    // Check vote passed
    require(proposal.yayVotes > proposal.nayVotes, "Voting: Proposal hasn't passed vote");

    // Check we're in execution window
    require(block.timestamp > proposal.voteCallTime + EXECUTION_START_OFFSET, "Voting: Execution window hasn't opened");
    require(block.timestamp < proposal.voteCallTime + EXECUTION_END_OFFSET, "Voting: Execution window has closed");

    // Check proposal hasn't been executed before
    require(!proposal.executed, "Voting: Proposal has already been executed");

    // Mark proposal as executed
    proposal.executed = true;

    Call[] memory actions = proposal.actions;

    // Loop over actions and execute
    for (uint256 i = 0; i < actions.length; i++) {
      // Execute action
      (bool successful, bytes memory returnData) = DELEGATOR_CONTRACT.callContract(
        actions[i].callContract,
        actions[i].data,
        actions[i].value
      );

      // If an action fails to execute, catch and bubble up reason with revert
      if (!successful) {
        revert ExecutionFailed(i, returnData);
      }
    }

    // Emit event
    emit Execution(_id);
  }
}