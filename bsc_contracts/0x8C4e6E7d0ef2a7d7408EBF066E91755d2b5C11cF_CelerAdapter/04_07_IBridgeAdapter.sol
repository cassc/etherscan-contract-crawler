// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

/**
 * @title The Interface of Bridge Adapter
 * @author Plug Exchange
 * @notice Deposit the bridge token through specific bridge adapter contract
 */
interface IBridgeAdapter {
  /**
   * @notice Transfer The token from one chain to another chain
   * @param amount The amount to transfer
   * @param recipient The Recipient wallet address
   * @param token The token which needs to bridge
   * @param data The bridge call data
   */
  function deposit(
    uint256 amount,
    address recipient,
    address token,
    bytes calldata data
  ) external payable returns (uint256 toChainId);
}