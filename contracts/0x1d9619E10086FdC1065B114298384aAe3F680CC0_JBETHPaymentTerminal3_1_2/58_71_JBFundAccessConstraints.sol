// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IJBPaymentTerminal} from './../interfaces/IJBPaymentTerminal.sol';

/// @custom:member terminal The terminal within which the distribution limit and the overflow allowance applies.
/// @custom:member token The token for which the fund access constraints apply.
/// @custom:member distributionLimit The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
/// @custom:member distributionLimitCurrency The currency of the distribution limit.
/// @custom:member overflowAllowance The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
/// @custom:member overflowAllowanceCurrency The currency of the overflow allowance.
struct JBFundAccessConstraints {
  IJBPaymentTerminal terminal;
  address token;
  uint256 distributionLimit;
  uint256 distributionLimitCurrency;
  uint256 overflowAllowance;
  uint256 overflowAllowanceCurrency;
}