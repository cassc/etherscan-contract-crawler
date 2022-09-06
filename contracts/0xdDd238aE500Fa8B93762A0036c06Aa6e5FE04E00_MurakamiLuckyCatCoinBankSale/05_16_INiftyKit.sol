// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface INiftyKit {
  /**
   * @dev Add fees from Collection
   */
  function addFees(uint256 amount) external;

  /**
   * @dev Add fees claimed by the Collection
   */
  function addFeesClaimed(uint256 amount) external;

  /**
   * @dev Get fees accrued by the account
   */
  function getFees(address account) external view returns (uint256);
}