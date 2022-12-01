// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MathUtils.sol";

library InterestUtils {
    using MathUtils for uint256;

    uint256 public constant VERSION = 1;

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
   * @notice Function to calculate the interest using a compounded interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
    function getCompoundedInterest(
        uint256 rate,
        uint256 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256) {
        uint256 exp = currentTimestamp - lastUpdateTimestamp;

        if (exp == 0) {
            return MathUtils.RAY;
        }

        uint256 expMinusOne = exp - 1;

        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

        uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

        uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
        uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

        uint256 secondTerm = exp * expMinusOne * basePowerTwo / 2;
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree / 6;

        return MathUtils.RAY + (ratePerSecond * exp) + secondTerm + thirdTerm;
    }
}