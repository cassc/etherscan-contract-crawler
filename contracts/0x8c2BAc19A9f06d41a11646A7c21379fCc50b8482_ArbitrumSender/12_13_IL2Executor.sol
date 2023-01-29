// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import { Delegator } from "./Delegator.sol";

interface IL2Executor {
  // Action structure
  struct Action {
    address callContract;
    bytes data;
    uint256 value;
  }

  /**
   * @notice Delegator address
   * @return Governance delegator to execute actions via
   */
  // solhint-disable-next-line func-name-mixedcase
  function DELEGATOR() external returns (Delegator);

  /**
   * @notice Creates new task
   * @param _actions - list of calls to execute for this task
   */
  function createTask(Action[] calldata _actions) external returns (uint256);

  /**
   * @notice Gets actions for a task
   * @param _tasks - task to get actions for
   * @return List of actions
   */
  function getActions(uint256 _tasks) external view returns (Action[] memory);

  /**
   * @notice Executes task
   * @dev Should execute via Governance Delegator
   * @param _task - task ID to execute
   */
  function executeTask(uint256 _task) external;
}