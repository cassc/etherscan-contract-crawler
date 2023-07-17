// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IProposalValidator} from '../interfaces/IProposalValidator.sol';
import {IGovernanceRobotKeeper} from '../interfaces/IGovernanceRobotKeeper.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';

/**
 * @author BGD Labs
 * @dev Aave chainlink keeper-compatible contract for proposal automation:
 * - checks if the proposal state could be moved to queued, executed or cancelled
 * - moves the proposal to queued/executed/cancelled if all the conditions are met
 */
contract EthRobotKeeper is Ownable, IGovernanceRobotKeeper {
  mapping(uint256 => bool) internal disabledProposals;
  IAaveGovernanceV2 public immutable GOVERNANCE_V2;
  uint256 public constant MAX_ACTIONS = 25;
  uint256 public constant MAX_SKIP = 20;

  error NoActionCanBePerformed();

  constructor(IAaveGovernanceV2 governanceV2Contract) {
    GOVERNANCE_V2 = governanceV2Contract;
  }

  /**
   * @dev run off-chain, checks if proposals should be moved to queued, executed or cancelled state
   */
  function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
    ActionWithId[] memory actionsWithIds = new ActionWithId[](MAX_ACTIONS);

    uint256 index = GOVERNANCE_V2.getProposalsCount();
    uint256 skipCount = 0;
    uint256 actionsCount = 0;

    // loops from the last proposalId until MAX_SKIP iterations, resets skipCount if an action could be performed
    while (index != 0 && skipCount <= MAX_SKIP && actionsCount < MAX_ACTIONS) {
      uint256 currentId = index - 1;

      IAaveGovernanceV2.ProposalState proposalState = GOVERNANCE_V2.getProposalState(currentId);
      IAaveGovernanceV2.ProposalWithoutVotes memory proposal = GOVERNANCE_V2.getProposalById(
        currentId
      );

      if (!isDisabled(currentId)) {
        if (isProposalInFinalState(proposalState)) {
          skipCount++;
        } else {
          if (canProposalBeCancelled(proposalState, proposal)) {
            actionsWithIds[actionsCount].id = currentId;
            actionsWithIds[actionsCount].action = ProposalAction.PerformCancel;
            actionsCount++;
          } else if (canProposalBeQueued(proposalState)) {
            actionsWithIds[actionsCount].id = currentId;
            actionsWithIds[actionsCount].action = ProposalAction.PerformQueue;
            actionsCount++;
          } else if (canProposalBeExecuted(proposalState, proposal)) {
            actionsWithIds[actionsCount].id = currentId;
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
   * @dev if proposal could be queued/executed/cancelled - executes queue/cancel/execute action on the governance contract
   * @param performData array of proposal ids, array of actions whether to queue, execute or cancel
   */
  function performUpkeep(bytes calldata performData) external override {
    ActionWithId[] memory actionsWithIds = abi.decode(performData, (ActionWithId[]));
    bool isActionPerformed;

    // executes action on proposalIds in order from first to last
    for (uint256 i = actionsWithIds.length; i > 0; i--) {
      uint256 currentId = i - 1;

      IAaveGovernanceV2.ProposalWithoutVotes memory proposal = GOVERNANCE_V2.getProposalById(
        actionsWithIds[currentId].id
      );
      IAaveGovernanceV2.ProposalState proposalState = GOVERNANCE_V2.getProposalState(
        actionsWithIds[currentId].id
      );

      if (
        actionsWithIds[currentId].action == ProposalAction.PerformCancel &&
        canProposalBeCancelled(proposalState, proposal)
      ) {
        try GOVERNANCE_V2.cancel(actionsWithIds[currentId].id) {
          isActionPerformed = true;
        } catch Error(string memory reason) {
          emit ActionFailed(actionsWithIds[currentId].id, actionsWithIds[currentId].action, reason);
        }
      } else if (
        actionsWithIds[currentId].action == ProposalAction.PerformQueue &&
        canProposalBeQueued(proposalState)
      ) {
        try GOVERNANCE_V2.queue(actionsWithIds[currentId].id) {
          isActionPerformed = true;
        } catch Error(string memory reason) {
          emit ActionFailed(actionsWithIds[currentId].id, actionsWithIds[currentId].action, reason);
        }
      } else if (
        actionsWithIds[currentId].action == ProposalAction.PerformExecute &&
        canProposalBeExecuted(proposalState, proposal)
      ) {
        try GOVERNANCE_V2.execute(actionsWithIds[currentId].id) {
          isActionPerformed = true;
        } catch Error(string memory reason) {
          emit ActionFailed(actionsWithIds[currentId].id, actionsWithIds[currentId].action, reason);
        }
      }
    }

    if (!isActionPerformed) revert NoActionCanBePerformed();
  }

  function isProposalInFinalState(
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

  function canProposalBeQueued(
    IAaveGovernanceV2.ProposalState proposalState
  ) internal pure returns (bool) {
    return proposalState == IAaveGovernanceV2.ProposalState.Succeeded;
  }

  function canProposalBeExecuted(
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

  function canProposalBeCancelled(
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
        GOVERNANCE_V2,
        proposal.creator,
        block.number - 1
      );
  }

  /// @inheritdoc IGovernanceRobotKeeper
  function isDisabled(uint256 id) public view returns (bool) {
    return disabledProposals[id];
  }

  /// @inheritdoc IGovernanceRobotKeeper
  function disableAutomation(uint256 id) external onlyOwner {
    disabledProposals[id] = true;
  }
}