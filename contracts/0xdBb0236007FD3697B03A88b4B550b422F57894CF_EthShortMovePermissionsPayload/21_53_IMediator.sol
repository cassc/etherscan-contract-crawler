// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMediator {
  error NotGuardianOrNotOverdue();
  error InvalidCaller();
  error ProposalIsCancelled();
  error LongProposalNotExecuted();

  event OverdueDateUpdated(uint256 overdueDate);
  event Executed();
  event Cancelled();

  /**
   * @notice return wether the migration was cancelled
   **/
  function getIsCancelled() external returns (bool);

  /**
   * @notice set the overdue date for the migration
   **/
  function setOverdueDate() external;

  /**
   * @notice execute governance v2-v3 migration
   * @dev contract must hold both short and long executor admin permissions
   **/
  function execute() external;

  /**
   * @notice cancel the migration and revert short/long executor permissions back to Governance v2
   * @dev emergency admin is able to cancel the migration
   **/
  function cancel() external;
}