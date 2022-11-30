// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMapleDesk {
  /**
   * @notice Maple Wallet Value in term of USDC
   */
  function getMapleWalletUsdcValue() external view returns (uint256);

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC20(
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) external;
}