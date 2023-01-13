// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @title ExplicitERC20
 * @author Set Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
  using SafeERC20 for IERC20;

  /**
   * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
   * Returning the real amount removed from sender's balance
   *
   * @param _token ERC20 token
   * @param _from  The account to transfer tokens from
   * @param _to The account to transfer tokens to
   * @param _quantity The quantity to transfer
   * @return amountTransferred Real amount removed from user balance
   * @return newBalance Final balance of the sender after transfer
   */
  function explicitSafeTransferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _quantity
  ) internal returns (uint256 amountTransferred, uint256 newBalance) {
    uint256 existingBalance = _token.balanceOf(_from);

    _token.safeTransferFrom(_from, _to, _quantity);

    newBalance = _token.balanceOf(_from);

    amountTransferred = existingBalance - newBalance;
  }

  /**
   * Transfers a token from the sender to the "_to" of quantity "_quantity".
   * Returning the real amount removed from sender's balance
   *
   * @param _token ERC20 token
   * @param _to The account to transfer tokens to
   * @param _quantity The quantity to transfer
   * @return amountTransferred Real amount removed from user balance
   * @return newBalance Final balance of the sender after transfer
   */
  function explicitSafeTransfer(
    IERC20 _token,
    address _to,
    uint256 _quantity
  ) internal returns (uint256 amountTransferred, uint256 newBalance) {
    uint256 existingBalance = _token.balanceOf(address(this));

    _token.safeTransfer(_to, _quantity);

    newBalance = _token.balanceOf(address(this));

    amountTransferred = existingBalance - newBalance;
  }
}