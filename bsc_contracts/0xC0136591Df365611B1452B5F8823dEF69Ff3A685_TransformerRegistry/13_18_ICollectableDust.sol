// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './IGovernable.sol';

/**
 * @title A contract that allows the current governor to withdraw funds
 * @notice This is meant to be used to recover any tokens that were sent to the contract
 *         by mistake
 */
interface ICollectableDust {
  /// @notice The balance of a given token
  struct TokenBalance {
    address token;
    uint256 balance;
  }

  /// @notice Thrown when trying to send dust to the zero address
  error DustRecipientIsZeroAddress();

  /**
   * @notice Emitted when dust is sent
   * @param token The token that was sent
   * @param amount The amount that was sent
   * @param recipient The address that received the tokens
   */
  event DustSent(address token, uint256 amount, address recipient);

  /**
   * @notice Returns the address of the protocol token
   * @dev Cannot be modified
   * @return The address of the protocol token;
   */
  function PROTOCOL_TOKEN() external view returns (address);

  /**
   * @notice Returns the balance of each of the given tokens
   * @dev Meant to be used for off-chain queries
   * @param tokens The tokens to check the balance for, can be ERC20s or the protocol token
   * @return The balances for the given tokens
   */
  function getBalances(address[] calldata tokens) external view returns (TokenBalance[] memory);

  /**
   * @notice Sends the given token to the recipient
   * @dev Can only be called by the governor
   * @param token The token to send to the recipient (can be an ERC20 or the protocol token)
   * @param amount The amount to transfer to the recipient
   * @param recipient The address of the recipient
   */
  function sendDust(
    address token,
    uint256 amount,
    address recipient
  ) external;
}