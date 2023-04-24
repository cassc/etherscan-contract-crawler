// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../utils/Governable.sol';
import '../SwapAdapter.sol';

abstract contract RevokableWithGovernor is SwapAdapter, Governable {
  /**
   * @notice Revokes ERC20 allowances for the given spenders
   * @dev Can only be called by the governor
   * @param _revokeActions The spenders and tokens to revoke
   */
  function revokeAllowances(RevokeAction[] calldata _revokeActions) external onlyGovernor {
    _revokeAllowances(_revokeActions);
  }
}