pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

library ScaledMath {
    /// @dev Perform scaled division
    /// @dev As per Compound's exponential library, we scale the numerator by 1e18 before dividing
    /// @dev This means that the result is scaled by 1e18 and needs to be divided by 1e18 outside this fn to get the actual value
    function sDivision(uint256 _numerator, uint256 _denominator) internal pure returns (uint256) {
        uint256 numeratorScaled = _numerator * 1e18;
        return numeratorScaled / _denominator;
    }
}