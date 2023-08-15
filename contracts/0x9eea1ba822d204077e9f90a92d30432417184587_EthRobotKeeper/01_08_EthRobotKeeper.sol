// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IProposalValidator} from '../interfaces/IProposalValidator.sol';
import {IEthRobotKeeper, AutomationCompatibleInterface} from '../interfaces/IEthRobotKeeper.sol';
import {IAaveCLRobotOperator} from '../interfaces/IAaveCLRobotOperator.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';

/**
 * @title EthRobotKeeper
 * @author BGD Labs
 * @dev Aave chainlink keeper-compatible contract for proposal automation:
 * - checks if the proposal state could be moved to queued, executed or cancelled
 * - moves the proposal to queued/executed/cancelled if all the conditions are met
 */
contract EthRobotKeeper is Ownable, IEthRobotKeeper {
  /// @inheritdoc IEthRobotKeeper
  address public immutable GOVERNANCE_V2;

  /// @inheritdoc IEthRobotKeeper
  uint256 public constant MAX_ACTIONS = 5;

  /// @inheritdoc IEthRobotKeeper
  uint256 public constant MAX_SKIP = 20;

  mapping(uint256 => bool) internal _disabledProposals;

  error NoActionCanBePerformed();

  /**
   * @param governanceV2 address of the governance contract.
   */
  constructor(address governanceV2) {
    GOVERNANCE_V2 = governanceV2;
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev run off-chain, checks if proposals should be moved to queued, executed or cancelled state
   */
  function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
    ActionWithId[] memory queueAndCancelActions = new ActionWithId[](MAX_ACTIONS);
    ActionWithId[] memory executeActions = new ActionWithId[](MAX_ACTIONS);

    uint256 index = IAaveGovernanceV2(GOVERNANCE_V2).getProposalsCount();
    uint256 skipCount = 0;
    uint256 queueAndCancelCount = 0;
    uint256 executeCount = 0;

    // loops from the last/latest proposalId until MAX_SKIP iterations. resets skipCount and checks more MAX_SKIP number
    // of proposals if any action could be performed. we only check proposals until MAX_SKIP iterations from the last/latest
    // proposalId or proposals where any action could be performed, and proposals before that will be not be checked by the keeper.
    while (index != 0 && skipCount <= MAX_SKIP) {
      uint256 proposalId = index - 1;

      IAaveGovernanceV2.ProposalState proposalState = IAaveGovernanceV2(GOVERNANCE_V2)
        .getProposalState(proposalId);
      IAaveGovernanceV2.ProposalWithoutVotes memory proposal = IAaveGovernanceV2(GOVERNANCE_V2)
        .getProposalById(proposalId);

      if (!isDisabled(proposalId)) {
        if (_isProposalInFinalState(proposalState)) {
          skipCount++;
        } else {
          if (
            _canProposalBeCancelled(proposalState, proposal) && queueAndCancelCount < MAX_ACTIONS
          ) {
            queueAndCancelActions[queueAndCancelCount].id = proposalId;
            queueAndCancelActions[queueAndCancelCount].action = ProposalAction.PerformCancel;
            queueAndCancelCount++;
          } else if (_canProposalBeQueued(proposalState) && queueAndCancelCount < MAX_ACTIONS) {
            queueAndCancelActions[queueAndCancelCount].id = proposalId;
            queueAndCancelActions[queueAndCancelCount].action = ProposalAction.PerformQueue;
            queueAndCancelCount++;
          } else if (
            _canProposalBeExecuted(proposalState, proposal) && executeCount < MAX_ACTIONS
          ) {
            executeActions[executeCount].id = proposalId;
            executeActions[executeCount].action = ProposalAction.PerformExecute;
            executeCount++;
          }
          skipCount = 0;
        }
      }

      index--;
    }

    if (queueAndCancelCount > 0) {
      // we batch multiple queue and cancel actions together so that we can perform the actions in a single performUpkeep.
      assembly {
        mstore(queueAndCancelActions, queueAndCancelCount)
      }
      return (true, abi.encode(queueAndCancelActions));
    } else if (executeCount > 0) {
      // we shuffle the actions list so that one action failing does not block the other actions of the keeper.
      executeActions = _squeezeAndShuffleActions(executeActions, executeCount);
      // squash and pick the first element from the shuffled array to perform execute.
      // we only perform one execute action due to gas limit limitation in one performUpkeep.
      assembly {
        mstore(executeActions, 1)
      }
      return (true, abi.encode(executeActions));
    }

    return (false, '');
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev if proposal could be queued/executed/cancelled - executes queue/cancel/execute action on the governance contract
   * @param performData array of proposal ids, array of actions whether to queue, execute or cancel
   */
  function performUpkeep(bytes calldata performData) external override {
    ActionWithId[] memory actionsWithIds = abi.decode(performData, (ActionWithId[]));
    bool isActionPerformed;

    // executes action on proposalIds
    for (uint256 i = actionsWithIds.length; i > 0; i--) {
      uint256 proposalId = actionsWithIds[i - 1].id;
      ProposalAction action = actionsWithIds[i - 1].action;

      IAaveGovernanceV2.ProposalWithoutVotes memory proposal = IAaveGovernanceV2(GOVERNANCE_V2)
        .getProposalById(proposalId);
      IAaveGovernanceV2.ProposalState proposalState = IAaveGovernanceV2(GOVERNANCE_V2)
        .getProposalState(proposalId);

      if (
        action == ProposalAction.PerformCancel && _canProposalBeCancelled(proposalState, proposal)
      ) {
        IAaveGovernanceV2(GOVERNANCE_V2).cancel(proposalId);
        isActionPerformed = true;
        emit ActionSucceeded(proposalId, action);
      } else if (action == ProposalAction.PerformQueue && _canProposalBeQueued(proposalState)) {
        IAaveGovernanceV2(GOVERNANCE_V2).queue(proposalId);
        isActionPerformed = true;
        emit ActionSucceeded(proposalId, action);
      } else if (
        action == ProposalAction.PerformExecute && _canProposalBeExecuted(proposalState, proposal)
      ) {
        IAaveGovernanceV2(GOVERNANCE_V2).execute(proposalId);
        isActionPerformed = true;
        emit ActionSucceeded(proposalId, action);
      }
    }

    if (!isActionPerformed) revert NoActionCanBePerformed();
  }

  /// @inheritdoc IEthRobotKeeper
  function toggleDisableAutomationById(uint256 proposalId) external onlyOwner {
    _disabledProposals[proposalId] = !_disabledProposals[proposalId];
  }

  /// @inheritdoc IEthRobotKeeper
  function isDisabled(uint256 proposalId) public view returns (bool) {
    return _disabledProposals[proposalId];
  }

  /**
   * @notice method to check if the proposal state is in final state.
   * @param proposalState the current state the proposal is in.
   * @return true if the proposal state is final state, false otherwise.
   */
  function _isProposalInFinalState(
    IAaveGovernanceV2.ProposalState proposalState
  ) internal pure returns (bool) {
    if (
      proposalState == IAaveGovernanceV2.ProposalState.Executed ||
      proposalState == IAaveGovernanceV2.ProposalState.Canceled ||
      proposalState == IAaveGovernanceV2.ProposalState.Expired ||
      proposalState == IAaveGovernanceV2.ProposalState.Failed
    ) {
      return true;
    }
    return false;
  }

  /**
   * @notice method to check if proposal could be queued.
   * @param proposalState the current state the proposal is in.
   * @return true if the proposal could be queued, false otherwise.
   */
  function _canProposalBeQueued(
    IAaveGovernanceV2.ProposalState proposalState
  ) internal pure returns (bool) {
    return proposalState == IAaveGovernanceV2.ProposalState.Succeeded;
  }

  /**
   * @notice method to check if proposal could be executed.
   * @param proposalState the current state the proposal is in.
   * @param proposal the proposal to check if it can be executed.
   * @return true if the proposal could be executed, false otherwise.
   */
  function _canProposalBeExecuted(
    IAaveGovernanceV2.ProposalState proposalState,
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal
  ) internal view returns (bool) {
    if (
      proposalState == IAaveGovernanceV2.ProposalState.Queued &&
      block.timestamp >= proposal.executionTime
    ) {
      return true;
    }
    return false;
  }

  /**
   * @notice method to check if proposal could be cancelled.
   * @param proposalState the current state the proposal is in.
   * @param proposal the proposal to check if it can be cancelled.
   * @return true if the proposal could be cancelled, false otherwise.
   */
  function _canProposalBeCancelled(
    IAaveGovernanceV2.ProposalState proposalState,
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal
  ) internal view returns (bool) {
    IProposalValidator proposalValidator = IProposalValidator(address(proposal.executor));
    if (
      proposalState == IAaveGovernanceV2.ProposalState.Expired ||
      proposalState == IAaveGovernanceV2.ProposalState.Canceled ||
      proposalState == IAaveGovernanceV2.ProposalState.Executed
    ) {
      return false;
    }
    return
      proposalValidator.validateProposalCancellation(
        IAaveGovernanceV2(GOVERNANCE_V2),
        proposal.creator,
        block.number - 1
      );
  }

  /**
   * @notice method to squeeze the actions array to the right size and shuffle them.
   * @param actions the list of actions to squeeze and shuffle.
   * @param actionsCount the total count of actions - used to squeeze the array to the right size.
   * @return actions array squeezed and shuffled.
   */
  function _squeezeAndShuffleActions(
    ActionWithId[] memory actions,
    uint256 actionsCount
  ) internal view returns (ActionWithId[] memory) {
    // we do not know the length in advance, so we init arrays with MAX_ACTIONS
    // and then squeeze the array using mstore
    assembly {
      mstore(actions, actionsCount)
    }

    // shuffle actions
    for (uint256 i = 0; i < actions.length; i++) {
      uint256 randomNumber = uint256(
        keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
      );
      uint256 n = i + (randomNumber % (actions.length - i));
      ActionWithId memory temp = actions[n];
      actions[n] = actions[i];
      actions[i] = temp;
    }

    return actions;
  }
}