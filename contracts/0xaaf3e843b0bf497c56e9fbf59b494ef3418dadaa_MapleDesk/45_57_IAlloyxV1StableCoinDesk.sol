// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyxDesk
 * @author AlloyX
 */
interface IAlloyxV1StableCoinDesk {
  /**
   * @notice An Alloy token holder can deposit their tokens and redeem them for USDC
   * @param _tokenAmount Number of Alloy Tokens
   */
  function depositAlloyxDURATokens(uint256 _tokenAmount) external;

  /**
   * @notice A Liquidity Provider can deposit supported stable coins for Alloy Tokens
   * @param _tokenAmount Number of stable coin
   */
  function depositUSDCCoin(uint256 _tokenAmount) external;
}