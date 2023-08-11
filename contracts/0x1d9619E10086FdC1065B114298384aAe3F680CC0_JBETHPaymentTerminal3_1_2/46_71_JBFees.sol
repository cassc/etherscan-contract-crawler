// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PRBMath} from '@paulrberg/contracts/math/PRBMath.sol';
import {JBConstants} from './../libraries/JBConstants.sol';

/// @notice Fee calculations.
library JBFees {
  /// @notice Returns the fee included in the specified _amount for the specified project.
  /// @param _amount The amount that the fee is based on, as a fixed point number with the same amount of decimals as this terminal.
  /// @param _feePercent The percentage of the fee, out of MAX_FEE.
  /// @param _feeDiscount The percentage discount that should be applied out of the max amount, out of MAX_FEE_DISCOUNT.
  /// @return The amount of the fee, as a fixed point number with the same amount of decimals as this terminal.
  function feeIn(
    uint256 _amount,
    uint256 _feePercent,
    uint256 _feeDiscount
  ) internal pure returns (uint256) {
    // Calculate the discounted fee.
    uint256 _discountedFeePercent = _feePercent -
      PRBMath.mulDiv(_feePercent, _feeDiscount, JBConstants.MAX_FEE_DISCOUNT);

    // The amount of tokens from the `_amount` to pay as a fee. If reverse, the fee taken from a payout of `_amount`.
    return
      _amount - PRBMath.mulDiv(_amount, JBConstants.MAX_FEE, _discountedFeePercent + JBConstants.MAX_FEE);
  }

  /// @notice Returns the fee amount paid from a payouts of _amount for the specified project.
  /// @param _amount The amount that the fee is based on, as a fixed point number with the same amount of decimals as this terminal.
  /// @param _feePercent The percentage of the fee, out of MAX_FEE.
  /// @param _feeDiscount The percentage discount that should be applied out of the max amount, out of MAX_FEE_DISCOUNT.
  /// @return The amount of the fee, as a fixed point number with the same amount of decimals as this terminal.
  function feeFrom(
    uint256 _amount,
    uint256 _feePercent,
    uint256 _feeDiscount
  ) internal pure returns (uint256) {
    // Calculate the discounted fee.
    uint256 _discountedFeePercent = _feePercent -
      PRBMath.mulDiv(_feePercent, _feeDiscount, JBConstants.MAX_FEE_DISCOUNT);

    // The amount of tokens from the `_amount` to pay as a fee. If reverse, the fee taken from a payout of `_amount`.
    return PRBMath.mulDiv(_amount, _discountedFeePercent, JBConstants.MAX_FEE);
  }
}