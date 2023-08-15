// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {JBDidPayData} from './../structs/JBDidPayData.sol';

/// @title Pay delegate
/// @notice Delegate called after JBTerminal.pay(..) logic completion (if passed by the funding cycle datasource)
interface IJBPayDelegate is IERC165 {
  /// @notice This function is called by JBPaymentTerminal.pay(..), after the execution of its logic
  /// @dev Critical business logic should be protected by an appropriate access control
  /// @param data the data passed by the terminal, as a JBDidPayData struct:
  function didPay(JBDidPayData calldata data) external payable;
}