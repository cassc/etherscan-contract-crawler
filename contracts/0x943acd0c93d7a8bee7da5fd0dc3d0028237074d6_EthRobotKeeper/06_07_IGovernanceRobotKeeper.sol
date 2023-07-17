// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationCompatibleInterface} from 'chainlink-brownie-contracts/interfaces/AutomationCompatibleInterface.sol';

/**
 * @title IGovernanceRobotKeeper
 * @author BGD Labs
 * @notice Defines the interface for the contract to automate actions on aave governance proposals.
 **/
interface IGovernanceRobotKeeper is AutomationCompatibleInterface {
  event ActionFailed(uint256 id, ProposalAction action, string reason);

  /**
   * @notice Actions that can be performed by the robot on the governance v2. Not used by L2 Robot as we only need to perform execute.
   * PerformQueue: performs queue action on the governance contract.
   * PerformExecute: performs execute action on the governance contract.
   * PerformCancel: performs cancel action on the governance contract.
   **/
  enum ProposalAction {
    PerformQueue,
    PerformExecute,
    PerformCancel
  }

  struct ActionWithId {
    uint256 id;
    ProposalAction action;
  }

  /**
   * @notice method to check if a proposalId or actionsSetId is disabled.
   * @param id - proposalId or actionsSetId to check if disabled.
   **/
  function isDisabled(uint256 id) external view returns (bool);

  /**
   * @notice method to disable automation for a proposalId or actionsSetId.
   * @param id - proposalId or actionsSetId to disable automation.
   **/
  function disableAutomation(uint256 id) external;
}