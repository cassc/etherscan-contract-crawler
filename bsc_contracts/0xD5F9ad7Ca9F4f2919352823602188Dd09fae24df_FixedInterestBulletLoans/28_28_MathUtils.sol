// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

// @dev Suppose WAD precision for interest rates
library MathUtils {
    uint256 constant BASIS_PRECISON = 10_000;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    function calculateLinearInterest(
        uint256 principal,
        uint256 rate,
        uint256 startTimestamp,
        uint256 endTimestamp
    )
        internal
        view
        returns (uint256)
    {
        if (startTimestamp >= endTimestamp) {
            return 0;
        }

        uint256 result = principal * rate * (endTimestamp - startTimestamp);
        unchecked {
            result = result / SECONDS_PER_YEAR / BASIS_PRECISON;
        }

        return result;
    }
}