// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/**
 * @title A contract that supports batching calls
 * @notice Contracts with this interface provide a function to batch together multiple calls
 *         in a single external call.
 */
interface IMulticall {
  /**
   * @notice Receives and executes a batch of function calls on this contract.
   * @param data A list of different function calls to execute
   * @return results The result of executing each of those calls
   */
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}