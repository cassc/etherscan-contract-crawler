// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDistributer {
  /**
   * @dev Distribute money
   */
  function distribute(uint256 amount) external;

  /**
   * @dev Display claimable amount
   */
  function claimable() external view returns (uint256);

  /**
   * @dev Prepares claiming
   */
  function prepareClaim(address account) external returns (uint256);
}