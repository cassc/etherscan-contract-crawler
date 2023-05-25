// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/**
 * @title Basis Mathematics
 * @notice Provides helpers to perform percentage calculations
 * @dev Percentages are [e2] i.e. with 2 decimals precision / basis point.
 */
library BasisMath {
  uint256 internal constant FULL_PERCENT = 1e4; // 100.00% / 1000 bp
  uint256 internal constant HALF_ONCE_SCALED = FULL_PERCENT / 2;

  /**
   * @dev Percentage pct, round 0.5+ up.
   * @param self The value to take a percentage pct
   * @param percentage The percentage to be calculated [e2]
   * @return pct self * percentage
   */
  function percentageOf(uint256 self, uint256 percentage)
    internal
    pure
    returns (uint256 pct)
  {
    if (self == 0 || percentage == 0) {
      pct = 0;
    } else {
      require(
        self <= (type(uint256).max - HALF_ONCE_SCALED) / percentage,
        "BasisMath/Overflow"
      );

      pct = (self * percentage + HALF_ONCE_SCALED) / FULL_PERCENT;
    }
  }

  /**
   * @dev Split value into percentage, round 0.5+ up.
   * @param self The value to split
   * @param percentage The percentage to be calculated [e2]
   * @return pct The percentage of the value
   * @return rem Anything leftover from the value
   */
  function splitBy(uint256 self, uint256 percentage)
    internal
    pure
    returns (uint256 pct, uint256 rem)
  {
    require(percentage <= FULL_PERCENT, "BasisMath/ExcessPercentage");
    pct = percentageOf(self, percentage);
    rem = self - pct;
  }
}