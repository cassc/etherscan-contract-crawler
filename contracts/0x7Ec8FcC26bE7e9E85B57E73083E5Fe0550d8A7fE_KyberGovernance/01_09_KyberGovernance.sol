// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {PermissionAdmin} from '@kyber.network/utils-sc/contracts/PermissionAdmin.sol';
import {IKyberGovernance} from '../interfaces/governance/IKyberGovernance.sol';
import {IExecutorWithTimelock} from '../interfaces/governance/IExecutorWithTimelock.sol';
import {IVotingPowerStrategy} from '../interfaces/governance/IVotingPowerStrategy.sol';
import {IProposalValidator} from '../interfaces/governance/IProposalValidator.sol';
import {getChainId} from '../misc/Helpers.sol';

/**
 * @title Kyber Governance contract for Kyber 3.0
 * - Create a Proposal
 * - Cancel a Proposal
 * - Queue a Proposal
 * - Execute a Proposal
 * - Submit Vote to a Proposal
 * Proposal States : Pending => Active => Succeeded(/Failed/Finalized)
 *                   => Queued => Executed(/Expired)
 *                   The transition to "Canceled" can appear in multiple states
 **/
contract KyberGovernance is IKyberGovernance, PermissionAdmin {
  using SafeMath for uint256;

  bytes32 public constant DOMAIN_TYPEHASH = keccak256(
    'EIP712Domain(string name,uint256 chainId,address verifyingContract)'
  );
  bytes32 public constant VOTE_EMITTED_TYPEHASH = keccak256(
    'VoteEmitted(uint256 id,uint256 optionBitMask)'
  );
  string public constant NAME = 'Kyber Governance';

  address private _daoOperator;
  uint256 private _proposalsCount;
  mapping(uint256 => Proposal) private _proposals;
  mapping(address => bool) private _authorizedExecutors;
  mapping(address => bool) private _authorizedVotingPowerStrategies;

  constructor(
    address admin,
    address daoOperator,
    address[] memory executors,
    address[] memory votingPowerStrategies
  ) PermissionAdmin(admin) {
    require(daoOperator != address(0), 'invalid dao operator');
    _daoOperator = daoOperator;

    _authorizeExecutors(executors);
    _authorizeVotingPowerStrategies(votingPowerStrategies);
  }

  /**
   * @dev Creates a Binary Proposal (needs to be validated by the Proposal Validator)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param strategy voting power strategy of the proposal
   * @param executionParams data for execution, includes
   *   targets list of contracts called by proposal's associated transactions
   *   weiValues list of value in wei for each proposal's associated transaction
   *   signatures list of function signatures (can be empty) to be used when created the callData
   *   calldatas list of calldatas: if associated signature empty,
   *        calldata ready, else calldata is arguments
   *   withDelegatecalls boolean, true = transaction delegatecalls the taget,
   *         else calls the target
   * @param startTime start timestamp to allow vote
   * @param endTime end timestamp of the proposal
   * @param link link to the proposal description
   **/
  function createBinaryProposal(
    IExecutorWithTimelock executor,
    IVotingPowerStrategy strategy,
    BinaryProposalParams memory executionParams,
    uint256 startTime,
    uint256 endTime,
    string memory link
  ) external override returns (uint256 proposalId) {
    require(executionParams.targets.length != 0, 'create binary invalid empty targets');
    require(
      executionParams.targets.length == executionParams.weiValues.length &&
        executionParams.targets.length == executionParams.signatures.length &&
        executionParams.targets.length == executionParams.calldatas.length &&
        executionParams.targets.length == executionParams.withDelegatecalls.length,
      'create binary inconsistent params length'
    );

    require(isExecutorAuthorized(address(executor)), 'create binary executor not authorized');
    require(
      isVotingPowerStrategyAuthorized(address(strategy)),
      'create binary strategy not authorized'
    );

    proposalId = _proposalsCount;
    require(
      IProposalValidator(address(executor)).validateBinaryProposalCreation(
        strategy,
        msg.sender,
        startTime,
        endTime,
        _daoOperator
      ),
      'validate proposal creation invalid'
    );

    ProposalWithoutVote storage newProposalData = _proposals[proposalId].proposalData;
    newProposalData.id = proposalId;
    newProposalData.proposalType = ProposalType.Binary;
    newProposalData.creator = msg.sender;
    newProposalData.executor = executor;
    newProposalData.targets = executionParams.targets;
    newProposalData.weiValues = executionParams.weiValues;
    newProposalData.signatures = executionParams.signatures;
    newProposalData.calldatas = executionParams.calldatas;
    newProposalData.withDelegatecalls = executionParams.withDelegatecalls;
    newProposalData.startTime = startTime;
    newProposalData.endTime = endTime;
    newProposalData.strategy = strategy;
    newProposalData.link = link;

    // only 2 options, YES and NO
    newProposalData.options.push('YES');
    newProposalData.options.push('NO');
    newProposalData.voteCounts.push(0);
    newProposalData.voteCounts.push(0);
    // use max voting power to finalise the proposal
    newProposalData.maxVotingPower = strategy.getMaxVotingPower();

    _proposalsCount++;
    // call strategy to record data if needed
    strategy.handleProposalCreation(proposalId, startTime, endTime);

    emit BinaryProposalCreated(
      proposalId,
      msg.sender,
      executor,
      strategy,
      executionParams.targets,
      executionParams.weiValues,
      executionParams.signatures,
      executionParams.calldatas,
      executionParams.withDelegatecalls,
      startTime,
      endTime,
      link,
      newProposalData.maxVotingPower
    );
  }

  /**
   * @dev Creates a Generic Proposal (needs to be validated by the Proposal Validator)
   *    It only gets the winning option without any executions
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param strategy voting power strategy of the proposal
   * @param options list of options to vote for
   * @param startTime start timestamp to allow vote
   * @param endTime end timestamp of the proposal
   * @param link link to the proposal description
   **/
  function createGenericProposal(
    IExecutorWithTimelock executor,
    IVotingPowerStrategy strategy,
    string[] memory options,
    uint256 startTime,
    uint256 endTime,
    string memory link
  )
    external override returns (uint256 proposalId)
  {
    require(
      isExecutorAuthorized(address(executor)),
      'create generic executor not authorized'
    );
    require(
      isVotingPowerStrategyAuthorized(address(strategy)),
      'create generic strategy not authorized'
    );
    proposalId = _proposalsCount;
    require(
      IProposalValidator(address(executor)).validateGenericProposalCreation(
        strategy,
        msg.sender,
        startTime,
        endTime,
        options,
        _daoOperator
      ),
      'validate proposal creation invalid'
    );
    Proposal storage newProposal = _proposals[proposalId];
    ProposalWithoutVote storage newProposalData = newProposal.proposalData;
    newProposalData.id = proposalId;
    newProposalData.proposalType = ProposalType.Generic;
    newProposalData.creator = msg.sender;
    newProposalData.executor = executor;
    newProposalData.startTime = startTime;
    newProposalData.endTime = endTime;
    newProposalData.strategy = strategy;
    newProposalData.link = link;
    newProposalData.options = options;
    newProposalData.voteCounts = new uint256[](options.length);
    // use max voting power to finalise the proposal
    newProposalData.maxVotingPower = strategy.getMaxVotingPower();

    _proposalsCount++;
    // call strategy to record data if needed
    strategy.handleProposalCreation(proposalId, startTime, endTime);

    emit GenericProposalCreated(
      proposalId,
      msg.sender,
      executor,
      strategy,
      options,
      startTime,
      endTime,
      link,
      newProposalData.maxVotingPower
    );
  }

  /**
   * @dev Cancels a Proposal.
   * - Callable by the _daoOperator with relaxed conditions,
   *   or by anybody if the conditions of cancellation on the executor are fulfilled
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external override {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    ProposalState state = getProposalState(proposalId);
    require(
      state != ProposalState.Executed &&
        state != ProposalState.Canceled &&
        state != ProposalState.Expired &&
        state != ProposalState.Finalized,
      'invalid state to cancel'
    );

    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    require(
      msg.sender == _daoOperator ||
        IProposalValidator(address(proposal.executor)).validateProposalCancellation(
          IKyberGovernance(this),
          proposalId,
          proposal.creator
        ),
      'validate proposal cancellation failed'
    );
    proposal.canceled = true;
    if (proposal.proposalType == ProposalType.Binary) {
      for (uint256 i = 0; i < proposal.targets.length; i++) {
        proposal.executor.cancelTransaction(
          proposal.targets[i],
          proposal.weiValues[i],
          proposal.signatures[i],
          proposal.calldatas[i],
          proposal.executionTime,
          proposal.withDelegatecalls[i]
        );
      }
    }
    // notify voting power strategy about the cancellation
    proposal.strategy.handleProposalCancellation(proposalId);

    emit ProposalCanceled(proposalId);
  }

  /**
   * @dev Queue the proposal (If Proposal Succeeded), only for Binary proposals
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external override {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    require(
      getProposalState(proposalId) == ProposalState.Succeeded,
      'invalid state to queue'
    );
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    // generic proposal does not have Succeeded state
    assert(proposal.proposalType == ProposalType.Binary);
    uint256 executionTime = block.timestamp.add(proposal.executor.getDelay());
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      _queueOrRevert(
        proposal.executor,
        proposal.targets[i],
        proposal.weiValues[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        executionTime,
        proposal.withDelegatecalls[i]
      );
    }
    proposal.executionTime = executionTime;

    emit ProposalQueued(proposalId, executionTime, msg.sender);
  }

  /**
   * @dev Execute the proposal (If Proposal Queued), only for Binary proposals
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external override payable {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    require(getProposalState(proposalId) == ProposalState.Queued, 'only queued proposals');
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    // generic proposal does not have Queued state
    assert(proposal.proposalType == ProposalType.Binary);
    proposal.executed = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      proposal.executor.executeTransaction{value: proposal.weiValues[i]}(
        proposal.targets[i],
        proposal.weiValues[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.executionTime,
        proposal.withDelegatecalls[i]
      );
    }
    emit ProposalExecuted(proposalId, msg.sender);
  }

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param optionBitMask bitmask optionBitMask of voter
   *  for Binary Proposal, optionBitMask should be either 1 or 2 (Accept/Reject)
   *  for Generic Proposal, optionBitMask is the bitmask of voted options
   **/
  function submitVote(uint256 proposalId, uint256 optionBitMask) external override {
    return _submitVote(msg.sender, proposalId, optionBitMask);
  }

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param optionBitMask the bit mask of voted options
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    uint256 optionBitMask,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        keccak256(
          abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), getChainId(), address(this))
        ),
        keccak256(abi.encode(VOTE_EMITTED_TYPEHASH, proposalId, optionBitMask))
      )
    );
    address signer = ecrecover(digest, v, r, s);
    require(signer != address(0), 'invalid signature');
    return _submitVote(signer, proposalId, optionBitMask);
  }

  /**
   * @dev Function to handle voting power changed for a voter
   *  caller must be the voting power strategy of the proposal
   * @param voter address that has changed the voting power
   * @param newVotingPower new voting power of that address,
   *   old voting power can be taken from records
   * @param proposalIds list proposal ids that belongs to this voting power strategy
   *   should update the voteCound of the active proposals in the list
   **/
  function handleVotingPowerChanged(
    address voter,
    uint256 newVotingPower,
    uint256[] calldata proposalIds
  ) external override {
    uint224 safeNewVotingPower = _safeUint224(newVotingPower);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      // only update for active proposals
      if (getProposalState(proposalIds[i]) != ProposalState.Active) continue;
      ProposalWithoutVote storage proposal = _proposals[proposalIds[i]].proposalData;
      require(address(proposal.strategy) == msg.sender, 'invalid voting power strategy');
      Vote memory vote = _proposals[proposalIds[i]].votes[voter];
      if (vote.optionBitMask == 0) continue; // not voted yet
      uint256 oldVotingPower = uint256(vote.votingPower);
      // update totalVotes of the proposal
      proposal.totalVotes = proposal.totalVotes.add(newVotingPower).sub(oldVotingPower);
      for (uint256 j = 0; j < proposal.options.length; j++) {
        if (vote.optionBitMask & (2**j) == 2**j) {
          // update voteCounts for each voted option
          proposal.voteCounts[j] = proposal.voteCounts[j].add(newVotingPower).sub(oldVotingPower);
        }
      }
      // update voting power of the voter
      _proposals[proposalIds[i]].votes[voter].votingPower = safeNewVotingPower;
      emit VotingPowerChanged(
        proposalIds[i],
        voter,
        vote.optionBitMask,
        vote.votingPower,
        safeNewVotingPower
      );
    }
  }

  /**
  * @dev Transfer dao operator
  * @param newDaoOperator new dao operator
  **/
  function transferDaoOperator(address newDaoOperator) external {
    require(msg.sender == _daoOperator, 'only dao operator');
    require(newDaoOperator != address(0), 'invalid dao operator');
    _daoOperator = newDaoOperator;
    emit DaoOperatorTransferred(newDaoOperator);
  }

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors)
    public override onlyAdmin
  {
    _authorizeExecutors(executors);
  }

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors)
    public override onlyAdmin
  {
    _unauthorizeExecutors(executors);
  }

  /**
   * @dev Add new addresses to the list of authorized strategies
   * @param strategies list of new addresses to be authorized strategies
   **/
  function authorizeVotingPowerStrategies(address[] memory strategies)
    public override onlyAdmin
  {
    _authorizeVotingPowerStrategies(strategies);
  }

  /**
   * @dev Remove addresses to the list of authorized strategies
   * @param strategies list of addresses to be removed as authorized strategies
   **/
  function unauthorizeVotingPowerStrategies(address[] memory strategies)
    public
    override
    onlyAdmin
  {
    _unauthorizedVotingPowerStrategies(strategies);
  }

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) public override view returns (bool) {
    return _authorizedExecutors[executor];
  }

  /**
   * @dev Returns whether an address is an authorized strategy
   * @param strategy address to evaluate as authorized strategy
   * @return true if authorized
   **/
  function isVotingPowerStrategyAuthorized(address strategy) public override view returns (bool) {
    return _authorizedVotingPowerStrategies[strategy];
  }

  /**
   * @dev Getter the address of the daoOperator, that can mainly cancel proposals
   * @return The address of the daoOperator
   **/
  function getDaoOperator() external override view returns (address) {
    return _daoOperator;
  }

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external override view returns (uint256) {
    return _proposalsCount;
  }

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVote memory object
   **/
  function getProposalById(uint256 proposalId)
    external
    override
    view
    returns (ProposalWithoutVote memory)
  {
    return _proposals[proposalId].proposalData;
  }

  /**
   * @dev Getter of the vote data of a proposal by id
   * including totalVotes, voteCounts and options
   * @param proposalId id of the proposal
   * @return (totalVotes, voteCounts, options)
   **/
  function getProposalVoteDataById(uint256 proposalId)
    external
    override
    view
    returns (
      uint256,
      uint256[] memory,
      string[] memory
    )
  {
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    return (proposal.totalVotes, proposal.voteCounts, proposal.options);
  }

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({uint32 bitOptionMask, uint224 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter)
    external
    override
    view
    returns (Vote memory)
  {
    return _proposals[proposalId].votes[voter];
  }

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId) public override view returns (ProposalState) {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.timestamp < proposal.startTime) {
      return ProposalState.Pending;
    } else if (block.timestamp <= proposal.endTime) {
      return ProposalState.Active;
    } else if (proposal.proposalType == ProposalType.Generic) {
      return ProposalState.Finalized;
    } else if (
      !IProposalValidator(address(proposal.executor)).isBinaryProposalPassed(
        IKyberGovernance(this),
        proposalId
      )
    ) {
      return ProposalState.Failed;
    } else if (proposal.executionTime == 0) {
      return ProposalState.Succeeded;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (proposal.executor.isProposalOverGracePeriod(this, proposalId)) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  function _queueOrRevert(
    IExecutorWithTimelock executor,
    address target,
    uint256 value,
    string memory signature,
    bytes memory callData,
    uint256 executionTime,
    bool withDelegatecall
  ) internal {
    require(
      !executor.isActionQueued(
        keccak256(abi.encode(target, value, signature, callData, executionTime, withDelegatecall))
      ),
      'duplicated action'
    );
    executor.queueTransaction(target, value, signature, callData, executionTime, withDelegatecall);
  }

  function _submitVote(
    address voter,
    uint256 proposalId,
    uint256 optionBitMask
  ) internal {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    require(getProposalState(proposalId) == ProposalState.Active, 'voting closed');
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    uint256 numOptions = proposal.options.length;
    if (proposal.proposalType == ProposalType.Binary) {
      // either Yes (1) or No (2)
      require(optionBitMask == 1 || optionBitMask == 2, 'wrong vote for binary proposal');
    } else {
      require(
        optionBitMask > 0 && optionBitMask < 2**numOptions,
        'invalid options for generic proposal'
      );
    }

    Vote memory vote = _proposals[proposalId].votes[voter];
    uint256 votingPower = proposal.strategy.handleVote(voter, proposalId, optionBitMask);
    if (vote.optionBitMask == 0) {
      // first time vote, increase the totalVotes of the proposal
      proposal.totalVotes = proposal.totalVotes.add(votingPower);
    }
    for (uint256 i = 0; i < proposal.options.length; i++) {
      bool hasVoted = (vote.optionBitMask & (2**i)) == 2**i;
      bool isVoting = (optionBitMask & (2**i)) == 2**i;
      if (hasVoted && !isVoting) {
        proposal.voteCounts[i] = proposal.voteCounts[i].sub(votingPower);
      } else if (!hasVoted && isVoting) {
        proposal.voteCounts[i] = proposal.voteCounts[i].add(votingPower);
      }
    }

    _proposals[proposalId].votes[voter] = Vote({
      optionBitMask: _safeUint32(optionBitMask),
      votingPower: _safeUint224(votingPower)
    });
    emit VoteEmitted(proposalId, voter, _safeUint32(optionBitMask), _safeUint224(votingPower));
  }

  function _authorizeExecutors(address[] memory executors) internal {
    for(uint256 i = 0; i < executors.length; i++) {
      _authorizedExecutors[executors[i]] = true;
      emit ExecutorAuthorized(executors[i]);
    }
  }

  function _unauthorizeExecutors(address[] memory executors) internal {
    for(uint256 i = 0; i < executors.length; i++) {
      _authorizedExecutors[executors[i]] = false;
      emit ExecutorUnauthorized(executors[i]);
    }
  }

  function _authorizeVotingPowerStrategies(address[] memory strategies) internal {
    for(uint256 i = 0; i < strategies.length; i++) {
      _authorizedVotingPowerStrategies[strategies[i]] = true;
      emit VotingPowerStrategyAuthorized(strategies[i]);
    }
  }

  function _unauthorizedVotingPowerStrategies(address[] memory strategies) internal {
    for(uint256 i = 0; i < strategies.length; i++) {
      _authorizedVotingPowerStrategies[strategies[i]] = false;
      emit VotingPowerStrategyUnauthorized(strategies[i]);
    }
  }

  function _safeUint224(uint256 value) internal pure returns (uint224) {
    require(value < 2**224 - 1, 'value is too big (uint224)');
    return uint224(value);
  }

  function _safeUint32(uint256 value) internal pure returns (uint32) {
    require(value < 2**32 - 1, 'value is too big (uint32)');
    return uint32(value);
  }
}