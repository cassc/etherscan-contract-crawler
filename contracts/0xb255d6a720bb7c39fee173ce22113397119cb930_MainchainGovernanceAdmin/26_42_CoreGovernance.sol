// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../libraries/Proposal.sol";
import "../../libraries/GlobalProposal.sol";
import "../../libraries/Ballot.sol";
import "../../interfaces/consumers/ChainTypeConsumer.sol";
import "../../interfaces/consumers/SignatureConsumer.sol";
import "../../interfaces/consumers/VoteStatusConsumer.sol";

abstract contract CoreGovernance is SignatureConsumer, VoteStatusConsumer, ChainTypeConsumer {
  using Proposal for Proposal.ProposalDetail;
  using GlobalProposal for GlobalProposal.GlobalProposalDetail;

  struct ProposalVote {
    VoteStatus status;
    bytes32 hash;
    uint256 againstVoteWeight; // Total weight of against votes
    uint256 forVoteWeight; // Total weight of for votes
    address[] forVoteds; // Array of addresses voting for
    address[] againstVoteds; // Array of addresses voting against
    uint256 expiryTimestamp;
    mapping(address => Signature) sig;
    mapping(address => bool) voted;
  }

  /// @dev Emitted when a proposal is created
  event ProposalCreated(
    uint256 indexed chainId,
    uint256 indexed round,
    bytes32 indexed proposalHash,
    Proposal.ProposalDetail proposal,
    address creator
  );
  /// @dev Emitted when a proposal is created
  event GlobalProposalCreated(
    uint256 indexed round,
    bytes32 indexed proposalHash,
    Proposal.ProposalDetail proposal,
    bytes32 globalProposalHash,
    GlobalProposal.GlobalProposalDetail globalProposal,
    address creator
  );
  /// @dev Emitted when the proposal is voted
  event ProposalVoted(bytes32 indexed proposalHash, address indexed voter, Ballot.VoteType support, uint256 weight);
  /// @dev Emitted when the proposal is approved
  event ProposalApproved(bytes32 indexed proposalHash);
  /// @dev Emitted when the vote is reject
  event ProposalRejected(bytes32 indexed proposalHash);
  /// @dev Emitted when the vote is expired
  event ProposalExpired(bytes32 indexed proposalHash);
  /// @dev Emitted when the proposal is executed
  event ProposalExecuted(bytes32 indexed proposalHash, bool[] successCalls, bytes[] returnDatas);

  /// @dev Mapping from chain id => vote round
  /// @notice chain id = 0 for global proposal
  mapping(uint256 => uint256) public round;
  /// @dev Mapping from chain id => vote round => proposal vote
  mapping(uint256 => mapping(uint256 => ProposalVote)) public vote;

  uint256 private _proposalExpiryDuration;

  constructor(uint256 _expiryDuration) {
    _setProposalExpiryDuration(_expiryDuration);
  }

  /**
   * @dev Creates new voting round by calculating the `_round` number of chain `_chainId`.
   * Increases the `_round` number if the previous one is not expired. Delete the previous proposal
   * if it is expired and not increase the `_round`.
   */
  function _createVotingRound(uint256 _chainId) internal returns (uint256 _round) {
    _round = round[_chainId];
    // Skip checking for the first ever round
    if (_round == 0) {
      _round = round[_chainId] = 1;
    } else {
      ProposalVote storage _latestProposalVote = vote[_chainId][_round];
      bool _isExpired = _tryDeleteExpiredVotingRound(_latestProposalVote);
      // Skip increasing round number if the latest round is expired, allow the vote to be overridden
      if (!_isExpired) {
        require(_latestProposalVote.status != VoteStatus.Pending, "CoreGovernance: current proposal is not completed");
        _round = ++round[_chainId];
      }
    }
  }

  /**
   * @dev Saves new round voting for the proposal `_proposalHash` of chain `_chainId`.
   */
  function _saveVotingRound(
    ProposalVote storage _vote,
    bytes32 _proposalHash,
    uint256 _expiryTimestamp
  ) internal {
    _vote.hash = _proposalHash;
    _vote.expiryTimestamp = _expiryTimestamp;
  }

  /**
   * @dev Proposes for a new proposal.
   *
   * Requirements:
   * - The chain id is not equal to 0.
   *
   * Emits the `ProposalCreated` event.
   *
   */
  function _proposeProposal(
    uint256 _chainId,
    uint256 _expiryTimestamp,
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    uint256[] memory _gasAmounts,
    address _creator
  ) internal virtual returns (Proposal.ProposalDetail memory _proposal) {
    require(_chainId != 0, "CoreGovernance: invalid chain id");
    uint256 _round = _createVotingRound(_chainId);

    _proposal = Proposal.ProposalDetail(_round, _chainId, _expiryTimestamp, _targets, _values, _calldatas, _gasAmounts);
    _proposal.validate(_proposalExpiryDuration);

    bytes32 _proposalHash = _proposal.hash();
    _saveVotingRound(vote[_chainId][_round], _proposalHash, _expiryTimestamp);
    emit ProposalCreated(_chainId, _round, _proposalHash, _proposal, _creator);
  }

  /**
   * @dev Proposes proposal struct.
   *
   * Requirements:
   * - The chain id is not equal to 0.
   * - The proposal nonce is equal to the new round.
   *
   * Emits the `ProposalCreated` event.
   *
   */
  function _proposeProposalStruct(Proposal.ProposalDetail memory _proposal, address _creator)
    internal
    virtual
    returns (uint256 _round)
  {
    uint256 _chainId = _proposal.chainId;
    require(_chainId != 0, "CoreGovernance: invalid chain id");
    _proposal.validate(_proposalExpiryDuration);

    bytes32 _proposalHash = _proposal.hash();
    _round = _createVotingRound(_chainId);
    _saveVotingRound(vote[_chainId][_round], _proposalHash, _proposal.expiryTimestamp);
    require(_round == _proposal.nonce, "CoreGovernance: invalid proposal nonce");
    emit ProposalCreated(_chainId, _round, _proposalHash, _proposal, _creator);
  }

  /**
   * @dev Proposes for a global proposal.
   *
   * Emits the `GlobalProposalCreated` event.
   *
   */
  function _proposeGlobal(
    uint256 _expiryTimestamp,
    GlobalProposal.TargetOption[] calldata _targetOptions,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    uint256[] memory _gasAmounts,
    address _roninTrustedOrganizationContract,
    address _gatewayContract,
    address _creator
  ) internal virtual {
    uint256 _round = _createVotingRound(0);
    GlobalProposal.GlobalProposalDetail memory _globalProposal = GlobalProposal.GlobalProposalDetail(
      _round,
      _expiryTimestamp,
      _targetOptions,
      _values,
      _calldatas,
      _gasAmounts
    );
    Proposal.ProposalDetail memory _proposal = _globalProposal.into_proposal_detail(
      _roninTrustedOrganizationContract,
      _gatewayContract
    );
    _proposal.validate(_proposalExpiryDuration);

    bytes32 _proposalHash = _proposal.hash();
    _saveVotingRound(vote[0][_round], _proposalHash, _expiryTimestamp);
    emit GlobalProposalCreated(_round, _proposalHash, _proposal, _globalProposal.hash(), _globalProposal, _creator);
  }

  /**
   * @dev Proposes global proposal struct.
   *
   * Requirements:
   * - The proposal nonce is equal to the new round.
   *
   * Emits the `GlobalProposalCreated` event.
   *
   */
  function _proposeGlobalStruct(
    GlobalProposal.GlobalProposalDetail memory _globalProposal,
    address _roninTrustedOrganizationContract,
    address _gatewayContract,
    address _creator
  ) internal virtual returns (Proposal.ProposalDetail memory _proposal) {
    _proposal = _globalProposal.into_proposal_detail(_roninTrustedOrganizationContract, _gatewayContract);
    _proposal.validate(_proposalExpiryDuration);

    bytes32 _proposalHash = _proposal.hash();
    uint256 _round = _createVotingRound(0);
    _saveVotingRound(vote[0][_round], _proposalHash, _globalProposal.expiryTimestamp);
    require(_round == _proposal.nonce, "CoreGovernance: invalid proposal nonce");
    emit GlobalProposalCreated(_round, _proposalHash, _proposal, _globalProposal.hash(), _globalProposal, _creator);
  }

  /**
   * @dev Casts vote for the proposal with data and returns whether the voting is done.
   *
   * Requirements:
   * - The proposal nonce is equal to the round.
   * - The vote is not finalized.
   * - The voter has not voted for the round.
   *
   * Emits the `ProposalVoted` event. Emits the `ProposalApproved`, `ProposalExecuted` or `ProposalRejected` once the
   * proposal is approved, executed or rejected.
   *
   */
  function _castVote(
    Proposal.ProposalDetail memory _proposal,
    Ballot.VoteType _support,
    uint256 _minimumForVoteWeight,
    uint256 _minimumAgainstVoteWeight,
    address _voter,
    Signature memory _signature,
    uint256 _voterWeight
  ) internal virtual returns (bool _done) {
    uint256 _chainId = _proposal.chainId;
    uint256 _round = _proposal.nonce;
    ProposalVote storage _vote = vote[_chainId][_round];

    if (_tryDeleteExpiredVotingRound(_vote)) {
      return true;
    }

    require(round[_proposal.chainId] == _round, "CoreGovernance: query for invalid proposal nonce");
    require(_vote.status == VoteStatus.Pending, "CoreGovernance: the vote is finalized");
    if (_voted(_vote, _voter)) {
      revert(string(abi.encodePacked("CoreGovernance: ", Strings.toHexString(uint160(_voter), 20), " already voted")));
    }

    _vote.voted[_voter] = true;
    // Stores the signature if it is not empty
    if (_signature.r > 0 || _signature.s > 0 || _signature.v > 0) {
      _vote.sig[_voter] = _signature;
    }
    emit ProposalVoted(_vote.hash, _voter, _support, _voterWeight);

    uint256 _forVoteWeight;
    uint256 _againstVoteWeight;
    if (_support == Ballot.VoteType.For) {
      _vote.forVoteds.push(_voter);
      _forVoteWeight = _vote.forVoteWeight += _voterWeight;
    } else if (_support == Ballot.VoteType.Against) {
      _vote.againstVoteds.push(_voter);
      _againstVoteWeight = _vote.againstVoteWeight += _voterWeight;
    } else {
      revert("CoreGovernance: unsupported vote type");
    }

    if (_forVoteWeight >= _minimumForVoteWeight) {
      _done = true;
      _vote.status = VoteStatus.Approved;
      emit ProposalApproved(_vote.hash);
      _tryExecute(_vote, _proposal);
    } else if (_againstVoteWeight >= _minimumAgainstVoteWeight) {
      _done = true;
      _vote.status = VoteStatus.Rejected;
      emit ProposalRejected(_vote.hash);
    }
  }

  /**
   * @dev When the contract is on Ronin chain, checks whether the proposal is expired and delete it if is expired.
   *
   * Emits the event `ProposalExpired` if the vote is expired.
   *
   * Note: This function assumes the vote `_proposalVote` is already created, consider verifying the vote's existence
   * before or it will emit an unexpected event of `ProposalExpired`.
   */
  function _tryDeleteExpiredVotingRound(ProposalVote storage _proposalVote) internal returns (bool _isExpired) {
    _isExpired =
      _getChainType() == ChainType.RoninChain &&
      _proposalVote.status == VoteStatus.Pending &&
      _proposalVote.expiryTimestamp <= block.timestamp;

    if (_isExpired) {
      emit ProposalExpired(_proposalVote.hash);

      for (uint256 _i; _i < _proposalVote.forVoteds.length; _i++) {
        delete _proposalVote.voted[_proposalVote.forVoteds[_i]];
        delete _proposalVote.sig[_proposalVote.forVoteds[_i]];
      }
      for (uint256 _i; _i < _proposalVote.againstVoteds.length; _i++) {
        delete _proposalVote.voted[_proposalVote.againstVoteds[_i]];
        delete _proposalVote.sig[_proposalVote.againstVoteds[_i]];
      }
      delete _proposalVote.status;
      delete _proposalVote.hash;
      delete _proposalVote.againstVoteWeight;
      delete _proposalVote.forVoteWeight;
      delete _proposalVote.forVoteds;
      delete _proposalVote.againstVoteds;
      delete _proposalVote.expiryTimestamp;
    }
  }

  /**
   * @dev Executes the proposal and update the vote status once the proposal is executable.
   */
  function _tryExecute(ProposalVote storage _vote, Proposal.ProposalDetail memory _proposal) internal {
    if (_proposal.executable()) {
      _vote.status = VoteStatus.Executed;
      (bool[] memory _successCalls, bytes[] memory _returnDatas) = _proposal.execute();
      emit ProposalExecuted(_vote.hash, _successCalls, _returnDatas);
    }
  }

  /**
   * @dev Sets the expiry duration for a new proposal.
   */
  function _setProposalExpiryDuration(uint256 _expiryDuration) internal {
    _proposalExpiryDuration = _expiryDuration;
  }

  /**
   * @dev Returns whether the voter casted for the proposal.
   */
  function _voted(ProposalVote storage _vote, address _voter) internal view returns (bool) {
    return _vote.voted[_voter];
  }

  /**
   * @dev Returns the expiry duration for a new proposal.
   */
  function _getProposalExpiryDuration() internal view returns (uint256) {
    return _proposalExpiryDuration;
  }

  /**
   * @dev Returns total weight from validators.
   */
  function _getTotalWeights() internal view virtual returns (uint256);

  /**
   * @dev Returns minimum vote to pass a proposal.
   */
  function _getMinimumVoteWeight() internal view virtual returns (uint256);

  /**
   * @dev Returns current context is running on whether Ronin chain or on mainchain.
   */
  function _getChainType() internal view virtual returns (ChainType);
}