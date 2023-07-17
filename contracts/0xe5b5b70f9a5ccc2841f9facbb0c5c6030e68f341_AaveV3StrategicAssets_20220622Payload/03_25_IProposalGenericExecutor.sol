// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Generic proposal interface allowing execution via MockExecutor
 */
interface IProposalGenericExecutor {
  function execute() external;
}