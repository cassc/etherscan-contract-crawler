// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGoldfinchDesk {
  /**
   * @notice GoldFinch PoolToken Value in Value in term of USDC
   */
  function getGoldFinchPoolTokenBalanceInUsdc() external view returns (uint256);

  /**
   * @notice Widthdraw GFI from pool token
   * @param _tokenIDs the IDs of token to sell
   */
  function withdrawGfiFromMultiplePoolTokens(uint256[] calldata _tokenIDs) external;

  /**
   * @notice Get the tokenID array of depositor
   * @param _depositor The address of the depositor
   */
  function getTokensAvailableForWithdrawal(address _depositor)
    external
    view
    returns (uint256[] memory);
}