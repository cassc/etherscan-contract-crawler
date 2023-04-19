// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IBackerRewards
 * @author AlloyX
 */
interface IBackerRewards {
  /**
   * @notice PoolToken request to withdraw multiple PoolTokens allocated rewards
   * @param tokenIds Array of pool token id
   */
  function withdrawMultiple(uint256[] calldata tokenIds) external;

  /**
   * @notice PoolToken request to withdraw all allocated rewards
   * @param tokenId Pool token id
   */
  function withdraw(uint256 tokenId) external;
}