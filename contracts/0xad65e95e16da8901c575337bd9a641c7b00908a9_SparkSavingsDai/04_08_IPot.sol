// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IPot
 *
 * @author Fuji Finance
 *
 * @notice Interface to read and interact with MakerDAO Pot contract
 */

interface IPot {
  /**
   * @notice Returns 1 + the current DAI Savings rate per second in RAY.
   */
  function dsr() external view returns (uint256);

  /**
   * @notice Returns the accumulated rate.
   */
  function chi() external view returns (uint256);
}