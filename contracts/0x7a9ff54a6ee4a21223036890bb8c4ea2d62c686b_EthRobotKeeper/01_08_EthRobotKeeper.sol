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
  uint256 public constant MAX_ACTIONS = 25;

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
    ActionWithId[] memory actionsWithIds = new ActionWithId[](MAX_ACTIONS);

    uint256 index = IAaveGovernanceV2(GOVERNANCE_V2).getProposalsCount();
    uint256 skipCount = 0;
    uint256 actionsCount = 0;

    // loops from the last/latest proposalId until MAX_SKIP iterations. resets skipCount and checks more MAX_SKIP number
    // of proposals if any action could be performed. we only check proposals until MAX_SKIP iterations from the last/latest
    // proposalId or proposals where any action could be performed, and proposals before that will be not be checked by the keeper.
    while (index != 0 && skipCount <= MAX_SKIP && actionsCount < MAX_ACTIONS) {
      uint256 proposalId = index - 1;

      IAaveGovernanceV2.ProposalState proposalState = IAaveGovernanceV2(GOVERNANCE_V2)
        .getProposalState(proposalId);
      IAaveGovernanceV2.ProposalWithoutVotes memory proposal = IAaveGovernanceV2(GOVERNANCE_V2)
        .getProposalById(proposalId);

      if (!isDisabled(proposalId)) {
        if (_isProposalInFinalState(proposalState)) {
          skipCount++;
        } else {
          if (_canProposalBeCancelled(proposalState, proposal)) {
            actionsWithIds[actionsCount].id = proposalId;
            actionsWithIds[actionsCount].action = ProposalAction.PerformCancel;
            actionsCount++;
          } else if (_canProposalBeQueued(proposalState)) {
            actionsWithIds[actionsCount].id = proposalId;
            actionsWithIds[actionsCount].action = ProposalAction.PerformQueue;
            actionsCount++;
          } else if (_canProposalBeExecuted(proposalState, proposal)) {
            actionsWithIds[actionsCount].id = proposalId;
            actionsWithIds[actionsCount].action = ProposalAction.PerformExecute;
            actionsCount++;
          }
          skipCount = 0;
        }
      }

      index--;
    }

    if (actionsCount > 0) {
      // we do not know the length in advance, so we init arrays with MAX_ACTIONS
      // and then squeeze the array using mstore
      assembly {
        mstore(actionsWithIds, actionsCount)
      }
      bytes memory performData = abi.encode(actionsWithIds);
      return (true, performData);
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

    // executes action on proposalIds in order from first to last
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
        try IAaveGovernanceV2(GOVERNANCE_V2).cancel(proposalId) {
          isActionPerformed = true;
          emit ActionSucceeded(proposalId, action);
        } catch Error(string memory reason) {
          emit ActionFailed(proposalId, action, reason);
        }
      } else if (action == ProposalAction.PerformQueue && _canProposalBeQueued(proposalState)) {
        try IAaveGovernanceV2(GOVERNANCE_V2).queue(proposalId) {
          isActionPerformed = true;
          emit ActionSucceeded(proposalId, action);
        } catch Error(string memory reason) {
          emit ActionFailed(proposalId, action, reason);
        }
      } else if (
        action == ProposalAction.PerformExecute && _canProposalBeExecuted(proposalState, proposal)
      ) {
        try IAaveGovernanceV2(GOVERNANCE_V2).execute(proposalId) {
          isActionPerformed = true;
          emit ActionSucceeded(proposalId, action);
        } catch Error(string memory reason) {
          emit ActionFailed(proposalId, action, reason);
        }
      }
    }

    if (!isActionPerformed) revert NoActionCanBePerformed();
  }

  /// @inheritdoc IEthRobotKeeper
  function toggleDisableAutomationById(
    uint256 proposalId
  ) external onlyOwner {
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
}