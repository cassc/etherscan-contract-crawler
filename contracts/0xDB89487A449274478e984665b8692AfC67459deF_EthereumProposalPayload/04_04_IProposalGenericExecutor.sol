// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IProposalGenericExecutor {
  function execute() external;

  event ProposalExecuted();
}