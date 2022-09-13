// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title SortedGoldfinchTranches Interface
 * @notice A editable sorted list of tranch pool addresses according to score
 * @author AlloyX
 */
interface ISortedGoldfinchTranches {
  /**
   * @notice A method to get the top k tranch pools
   * @param k the top k tranch pools
   */
  function getTop(uint256 k) external view returns (address[] memory);

  /**
   * @notice A method to get the top k tranch pools
   * @param tranch the address of tranch
   */
  function isTranchInside(address tranch) external view returns (bool);
}