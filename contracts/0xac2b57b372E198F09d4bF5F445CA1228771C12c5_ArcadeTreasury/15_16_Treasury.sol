// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title TreasuryErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains all custom errors for the Arcade Treasury contract.
 * All errors are prefixed by  "T_" for Treasury. Errors located in one place
 * to make it possible to holistically look at all the failure cases.
 */

/**
 * @notice Zero address passed in where not allowed.
 *
 * @param addressType                The name of the parameter for which a zero
 *                                   address was provided.
 */
error T_ZeroAddress(string addressType);

/**
 * @notice Cannot pass zero as an amount.
 */
error T_ZeroAmount();

/**
 * @notice Thresholds must be in ascending order.
 */
error T_ThresholdsNotAscending();

/**
 * @notice Array lengths must match.
 */
error T_ArrayLengthMismatch();

/**
 * @notice External call failed.
 */
error T_CallFailed();

/**
 * @notice Cannot withdraw or approve more than each tokens preset spend limits per block.
 */
error T_BlockSpendLimit();

/**
 * @notice Cannot make calls to addresses which have thresholds set. This is also a way to block
 * calls to unwanted addresses or bypass treasury withdraw functions.
 *
 * @param target               Specified address of the target contract.
 */
error T_InvalidTarget(address target);

/**
 * @notice When setting a new GSC allowance for a token it cannot be more than
 * that tokens small spend threshold.
 *
 * @param newAllowance             New allowance to set.
 * @param smallSpendThreshold      Maximum amount that can be approved for the GSC.
 */
error T_InvalidAllowance(uint256 newAllowance, uint256 smallSpendThreshold);

/**
 * @notice Must wait 7 days since last allowance was set to set a new one.
 *
 * @param currentTime             Current block timestamp.
 * @param coolDownPeriodEnd       Time when an allowance can be set.
 */
error T_CoolDownPeriod(uint256 currentTime, uint256 coolDownPeriodEnd);