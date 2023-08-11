// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev GuardianTimeMath library. Provides support for converting between guardian fees and purchased storage time
 */
library GuardianTimeMath {
    /**
     * @dev Calculates the fee amount associated with the items
     * scaledByNumItems based on currGuardianFeePaidUntil guardianClassFeeRate
     * (scaled by the number being moved, for semi-fungibles).
     * @param currGuardianFeePaidUntil a timestamp that describes until when storage has been paid.
     * @param guardianClassFeeRate a guardian's guardian fee rate. Amount per second.
     * @param scaledByNumItems the number of items that are being stored by a guardian at the time of the query.
     * @return the remaining amount of guardian fee that is left within the `currGuardianFeePaidUntil` at the `guardianClassFeeRate` rate for `scaledByNumItems` items
     */
    function calculateRemainingFeeAmount(
        uint256 currGuardianFeePaidUntil,
        uint256 guardianClassFeeRate,
        uint256 guardianFeeRatePeriod,
        uint256 scaledByNumItems
    ) internal view returns (uint256) {
        if (currGuardianFeePaidUntil <= block.timestamp) {
            return 0;
        } else {
            return ((((currGuardianFeePaidUntil - block.timestamp) *
                guardianClassFeeRate) * scaledByNumItems) /
                guardianFeeRatePeriod);
        }
    }

    /**
     * @dev Calculates added guardian storage time based on
     * guardianFeePaid guardianClassFeeRate and numItems
     * (scaled by the number being moved, for semi-fungibles).
     * @param guardianFeePaid the amount of guardian fee that is being paid.
     * @param guardianClassFeeRate a guardian's guardian fee rate. Amount per time period.
     * @param guardianFeeRatePeriod the size of the period used in the guardian fee rate.
     * @param numItems the number of items that are being stored by a guardian at the time of the query.
     * @return the amount of guardian time that can be purchased from `guardianFeePaid` fee amount at the `guardianClassFeeRate` rate for `numItems` items
     */
    function calculateAddedGuardianTime(
        uint256 guardianFeePaid,
        uint256 guardianClassFeeRate,
        uint256 guardianFeeRatePeriod,
        uint256 numItems
    ) internal pure returns (uint256) {
        return
            (guardianFeePaid * guardianFeeRatePeriod) /
            (guardianClassFeeRate * numItems);
    }

    /**
     * @dev Function that allows us to transform an amount from the internal, 18 decimal format, to one that has another decimal precision.
     * @param internalAmount the amount in 18 decimal represenation.
     * @param toDecimals the amount of decimal precision we want the amount to have
     */
    function transformDecimalPrecision(
        uint256 internalAmount,
        uint256 toDecimals
    ) internal pure returns (uint256) {
        return (internalAmount / (10 ** (18 - toDecimals)));
    }
}