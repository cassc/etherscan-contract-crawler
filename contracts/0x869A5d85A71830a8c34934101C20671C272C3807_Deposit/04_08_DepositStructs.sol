// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev A DepositItem specifies token address, token identifier to be
 *      transferred via the Deposit.
 */
struct DepositItem {
  address token;
  uint256 identifier;
}