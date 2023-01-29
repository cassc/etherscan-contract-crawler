// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import { AddressAliasHelper } from "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import { ArbRetryableTx } from "@arbitrum/nitro-contracts/src/precompiles/ArbRetryableTx.sol";

import { Delegator } from "../Delegator.sol";

import { IL2Executor } from "../IL2Executor.sol";

/**
 * @title Executor
 * @author Railgun Contributors
 * @notice Stores instructions to execute after L1 sender confirms
 */
contract ArbitrumExecutor is IL2Executor {
  // Addresses
  ArbRetryableTx public constant ARB_RETRYABLE_TX =
    ArbRetryableTx(0x000000000000000000000000000000000000006E);
  // solhint-disable-next-line var-name-mixedcase
  address public immutable SENDER_L1; // Voting contract on L1
  // solhint-disable-next-line var-name-mixedcase
  Delegator public immutable DELEGATOR; // Delegator contract

  uint256 public constant EXPIRY_TIME = 40 days;

  enum ExecutionState {
    Created,
    AwaitingExecution,
    Executed
  }

  // Task structure
  struct Task {
    uint256 creationTime; // Creation time of task
    ExecutionState state; // Execution state of task
    Action[] actions; // Calls to execute
  }

  // Task queue
  Task[] public tasks;

  // Task events
  event TaskCreated(uint256 id);
  event TaskReady(uint256 id);
  event TaskExecuted(uint256 id);

  // Errors event
  error ExecutionFailed(uint256 index, bytes data);

  /**
   * @notice Sets contract addresses
   * @param _senderL1 - sender contract on L1
   * @param _delegator - delegator contract
   */
  constructor(address _senderL1, Delegator _delegator) {
    SENDER_L1 = _senderL1;
    DELEGATOR = _delegator;
  }

  /**
   * @notice Creates new task
   * @param _actions - list of calls to execute for this task
   */
  function createTask(Action[] calldata _actions) external returns (uint256) {
    uint256 taskID = tasks.length;

    // Get new task
    Task storage task = tasks.push();

    // Set task creation time
    task.creationTime = block.timestamp;

    // Set task execution state
    task.state = ExecutionState.Created;

    // Set call list
    // Loop over actions and copy manually as solidity doesn't support copying struct arrays from calldata
    for (uint256 i = 0; i < _actions.length; i += 1) {
      task.actions.push(Action(_actions[i].callContract, _actions[i].data, _actions[i].value));
    }

    // Emit event
    emit TaskCreated(taskID);

    return taskID;
  }

  /**
   * @notice Gets actions for a task
   * @param _tasks - task to get actions for
   */
  function getActions(uint256 _tasks) external view returns (Action[] memory) {
    return tasks[_tasks].actions;
  }

  /**
   * @notice Convenience function to get minimum time newly created tickets will be redeemable
   */
  function newTicketTimeout() external view returns (uint256) {
    return ARB_RETRYABLE_TX.getLifetime();
  }

  /**
   * @notice Convenience function to get time left for ticket redemption
   * @param _ticket - ticket ID to redeem
   */
  function ticketTimeLeft(uint256 _ticket) external view returns (uint256) {
    return ARB_RETRYABLE_TX.getTimeout(bytes32(_ticket));
  }

  /**
   * @notice Convenience function to execute retryable ticket redeem
   * @param _ticket - ticket ID to redeem
   */
  function redeem(uint256 _ticket) external returns (bytes32) {
    return ARB_RETRYABLE_TX.redeem(bytes32(_ticket));
  }

  /**
   * @notice Executes task
   * @param _task - task ID to execute
   */
  function readyTask(uint256 _task) external {
    // Check cross chain call
    require(
      msg.sender == AddressAliasHelper.applyL1ToL2Alias(SENDER_L1),
      "ArbitrumExecutor: Caller is not L1 sender contract"
    );

    // Get task
    Task storage task = tasks[_task];

    // Check task hasn't already been executed
    require(
      task.state == ExecutionState.Created,
      "ArbitrumExecutor: Task has already been executed"
    );

    // Set task can execute
    task.state = ExecutionState.AwaitingExecution;

    // Emit event
    emit TaskReady(_task);
  }

  /**
   * @notice Executes task
   * @param _task - task ID to execute
   */
  function executeTask(uint256 _task) external {
    // Get task
    Task storage task = tasks[_task];

    // Check task can be executed
    require(
      task.state == ExecutionState.AwaitingExecution,
      "ArbitrumExecutor: Task not marked as executable"
    );

    // Check task hasn't expired
    require(
      block.timestamp < task.creationTime + EXPIRY_TIME,
      "ArbitrumExecutor: Task has expired"
    );

    // Mark task as executed
    task.state = ExecutionState.Executed;

    // Loop over actions and execute
    for (uint256 i = 0; i < task.actions.length; i += 1) {
      // Execute action
      (bool successful, bytes memory returnData) = DELEGATOR.callContract(
        task.actions[i].callContract,
        task.actions[i].data,
        task.actions[i].value
      );

      // If an action fails to execute, catch and bubble up reason with revert
      if (!successful) {
        revert ExecutionFailed(i, returnData);
      }
    }

    // Emit event
    emit TaskExecuted(_task);
  }
}