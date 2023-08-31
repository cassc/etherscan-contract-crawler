// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IHOPE {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);
}