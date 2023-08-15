// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationCompatibleInterface} from 'chainlink-brownie-contracts/interfaces/AutomationCompatibleInterface.sol';

/**
 * @title IEthRobotKeeper
 * @author BGD Labs
 * @notice Defines the interface for the contract to automate actions on aave governance v2 proposals Eth Mainnet.
 */
interface IEthRobotKeeper is AutomationCompatibleInterface {
  /**
   * @dev Emitted when performUpkeep is called and actions are executed.
   * @param id proposal id of successful action.
   * @param action successful action performed on the proposal.
   */
  event ActionSucceeded(uint256 indexed id, ProposalAction indexed action);

  /**
   * @notice Actions that can be performed by the robot on the governance v2.
   * @param PerformQueue: performs queue action on the governance contract.
   * @param PerformExecute: performs execute action on the governance contract.
   * @param PerformCancel: performs cancel action on the governance contract.
   */
  enum ProposalAction {
    PerformQueue,
    PerformExecute,
    PerformCancel
  }

  /**
   * @notice holds action to be performed for a given proposalId.
   * @param id proposal id for which action needs to be performed.
   * @param action action to be perfomed for the proposalId.
   */
  struct ActionWithId {
    uint256 id;
    ProposalAction action;
  }

  /**
   * @notice method called by owner / robot guardian to disable/enabled automation on a specific proposalId.
   * @param proposalId proposalId for which we need to disable/enable automation.
   */
  function toggleDisableAutomationById(uint256 proposalId) external;

  /**
   * @notice method to check if automation for the proposalId is disabled/enabled.
   * @param proposalId proposalId to check if automation is disabled or not.
   * @return bool if automation for proposalId is disabled or not.
   */
  function isDisabled(uint256 proposalId) external view returns (bool);

  /**
   * @notice method to get the address of the aave governance v2 contract.
   * @return governance v2 contract address.
   */
  function GOVERNANCE_V2() external returns (address);

  /**
   * @notice method to get the maximum number of queue and actions that can be performed by the keeper in one performUpkeep.
   * This value is also used to determine the max size of execute actions array, which is used for randomization of execute action.
   * @return max number of actions for queue / cancel. max size of execute actions array to be used for randomization for execute action.
   */
  function MAX_ACTIONS() external returns (uint256);

  /**
   * @notice method to get maximum number of proposals to check before the latest proposal, if an action could be performed upon.
   * @return max number of skips.
   */
  function MAX_SKIP() external returns (uint256);
}