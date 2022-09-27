// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/// @title Fee Math library
/// @notice Provides functions to calculate and apply fees to amounts
library FeeMath {
  /// @notice How much would a 1% fee be
  uint24 public constant FEE_PRECISION = 10000;

  /// @notice Takes a fee and an amount that has had the fee subtracted, and returns the amount that was subtracted
  /// @param _fee Fee that was applied
  /// @param _subtractionResult Amount that had the fee subtracted
  /// @return The amount that was subtracted
  function calculateSubtractedFee(uint32 _fee, uint256 _subtractionResult) internal pure returns (uint256) {
    return (_subtractionResult * _fee) / (FEE_PRECISION * 100 - _fee);
  }

  /// @notice Takes a fee and applies it to a certain amount. So if fee is 0.6%, it would return the 0.6% of the given amount
  /// @param _fee Fee to apply
  /// @param _amount Amount to apply the fee to
  /// @return The calculated fee
  function calculateFeeForAmount(uint32 _fee, uint256 _amount) internal pure returns (uint256) {
    return (_amount * _fee) / FEE_PRECISION / 100;
  }

  /// @notice Takes a fee and a certain amount, and subtracts the fee. So if fee is 0.6%, it would return 99.4% of the given amount
  /// @param _fee Fee to subtract
  /// @param _amount Amount that subtract the fee from
  /// @return The amount with the fee subtracted
  function subtractFeeFromAmount(uint32 _fee, uint256 _amount) internal pure returns (uint256) {
    return (_amount * (FEE_PRECISION - _fee / 100)) / FEE_PRECISION;
  }
}