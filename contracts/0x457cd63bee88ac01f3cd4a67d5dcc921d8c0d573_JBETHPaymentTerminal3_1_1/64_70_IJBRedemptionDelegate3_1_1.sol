// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {JBDidRedeemData3_1_1} from './../structs/JBDidRedeemData3_1_1.sol';

/// @title Redemption delegate
/// @notice Delegate called after JBTerminal.redeemTokensOf(..) logic completion (if passed by the funding cycle datasource)
interface IJBRedemptionDelegate3_1_1 is IERC165 {
  /// @notice This function is called by JBPaymentTerminal.redeemTokensOf(..), after the execution of its logic
  /// @dev Critical business logic should be protected by an appropriate access control
  /// @param data the data passed by the terminal, as a JBDidRedeemData struct:
  function didRedeem(JBDidRedeemData3_1_1 calldata data) external payable;
}