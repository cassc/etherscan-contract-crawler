// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../utils/Governable.sol';
import '../SwapAdapter.sol';

abstract contract CollectableWithGovernor is SwapAdapter, Governable {
  /**
   * @notice Sends the given token to the recipient
   * @dev Can only be called by the governor
   * @param _token The token to send to the recipient (can be an ERC20 or the protocol token)
   * @param _amount The amount to transfer to the recipient
   * @param _recipient The address of the recipient
   */
  function sendDust(
    address _token,
    uint256 _amount,
    address _recipient
  ) external onlyGovernor {
    _sendToRecipient(_token, _amount, _recipient);
  }
}