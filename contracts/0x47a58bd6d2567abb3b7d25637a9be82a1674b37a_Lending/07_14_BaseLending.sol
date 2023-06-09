// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./RoleAware.sol";

/// @title Base lending behavior
abstract contract BaseLending {
    uint256 constant FP48 = 2**48;
    uint256 constant ACCUMULATOR_INIT = 10**18;

    uint256 constant hoursPerYear = 365 days / (1 hours);
    uint256 constant CHANGE_POINT = 82;
    uint256 public normalRatePerPercent =
        (FP48 * 12) / hoursPerYear / CHANGE_POINT / 100;
    uint256 public highRatePerPercent =
        (FP48 * (135 - 12)) / hoursPerYear / (100 - CHANGE_POINT) / 100;

    struct YieldAccumulator {
        uint256 accumulatorFP;
        uint256 lastUpdated;
        uint256 hourlyYieldFP;
    }

    struct LendingMetadata {
        uint256 totalLending;
        uint256 totalBorrowed;
        uint256 lendingCap;
        uint256 cumulIncentiveAllocationFP;
        uint256 incentiveLastUpdated;
        uint256 incentiveEnd;
        uint256 incentiveTarget;
    }
    mapping(address => LendingMetadata) public lendingMeta;

    /// @dev accumulate interest per issuer (like compound indices)
    mapping(address => YieldAccumulator) public borrowYieldAccumulators;

    /// @dev simple formula for calculating interest relative to accumulator
    function applyInterest(
        uint256 balance,
        uint256 accumulatorFP,
        uint256 yieldQuotientFP
    ) internal pure returns (uint256) {
        // 1 * FP / FP = 1
        return (balance * accumulatorFP) / yieldQuotientFP;
    }

    function currentLendingRateFP(uint256 totalLending, uint256 totalBorrowing)
        internal
        view
        returns (uint256 rate)
    {
        rate = FP48;
        uint256 utilizationPercent =
            totalLending > 0 ? (100 * totalBorrowing) / totalLending : 0;
        if (utilizationPercent < CHANGE_POINT) {
            rate += utilizationPercent * normalRatePerPercent;
        } else {
            rate +=
                CHANGE_POINT *
                normalRatePerPercent +
                (utilizationPercent - CHANGE_POINT) *
                highRatePerPercent;
        }
    }

    /// @dev minimum
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }

    /// @dev maximum
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

    /// Available tokens to this issuance
    function issuanceBalance(address issuance)
        internal
        view
        virtual
        returns (uint256);
}