// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./BaseLending.sol";

struct HourlyBond {
    uint256 amount;
    uint256 yieldQuotientFP;
    uint256 moduloHour;
    uint256 incentiveAllocationStart;
}

/// @title Here we offer subscriptions to auto-renewing hourly bonds
/// Funds are locked in for an 50 minutes per hour, while interest rates float
abstract contract HourlyBondSubscriptionLending is BaseLending {
    mapping(address => YieldAccumulator) hourlyBondYieldAccumulators;

    uint256 constant RATE_UPDATE_WINDOW = 10 minutes;
    uint256 public withdrawalWindow = 20 minutes;
    uint256 constant MAX_HOUR_UPDATE = 4;
    // issuer => holder => bond record
    mapping(address => mapping(address => HourlyBond))
        public hourlyBondAccounts;

    uint256 public borrowingFactorPercent = 200;

    uint256 constant borrowMinAPR = 25;
    uint256 constant borrowMinHourlyYield =
        FP48 + (borrowMinAPR * FP48) / 1000 / hoursPerYear;

    function _makeHourlyBond(
        address issuer,
        address holder,
        uint256 amount
    ) internal {
        HourlyBond storage bond = hourlyBondAccounts[issuer][holder];
        LendingMetadata storage meta = lendingMeta[issuer];
        addToTotalLending(meta, amount);
        updateHourlyBondAmount(issuer, bond, holder);

        if (bond.amount == 0) {
            bond.moduloHour = block.timestamp % (1 hours);
        }
        bond.amount += amount;
    }

    function updateHourlyBondAmount(
        address issuer,
        HourlyBond storage bond,
        address holder
    ) internal {
        uint256 yieldQuotientFP = bond.yieldQuotientFP;

        YieldAccumulator storage yA =
            getUpdatedHourlyYield(
                issuer,
                hourlyBondYieldAccumulators[issuer],
                RATE_UPDATE_WINDOW
            );

        LendingMetadata storage meta = lendingMeta[issuer];

        if (yieldQuotientFP > 0) {
            disburseIncentive(bond, meta, holder);
            uint256 oldAmount = bond.amount;

            bond.amount = applyInterest(
                bond.amount,
                yA.accumulatorFP,
                yieldQuotientFP
            );

            uint256 deltaAmount = bond.amount - oldAmount;
            addToTotalLending(meta, deltaAmount);
        } else {
            bond.incentiveAllocationStart = meta.cumulIncentiveAllocationFP;
        }
        bond.yieldQuotientFP = yA.accumulatorFP;
    }

    // Retrieves bond balance for issuer and holder
    function viewHourlyBondAmount(address issuer, address holder)
        public
        view
        returns (uint256)
    {
        HourlyBond storage bond = hourlyBondAccounts[issuer][holder];
        uint256 yieldQuotientFP = bond.yieldQuotientFP;

        uint256 cumulativeYield =
            viewCumulativeYieldFP(
                hourlyBondYieldAccumulators[issuer],
                block.timestamp
            );

        if (yieldQuotientFP > 0) {
            return applyInterest(bond.amount, cumulativeYield, yieldQuotientFP);
        } else {
            return bond.amount;
        }
    }

    function _withdrawHourlyBond(
        address issuer,
        HourlyBond storage bond,
        uint256 amount,
        address holder
    ) internal {
        subtractFromTotalLending(lendingMeta[issuer], amount);
        updateHourlyBondAmount(issuer, bond, holder);

        // how far the current hour has advanced (relative to acccount hourly clock)
        uint256 currentOffset = (block.timestamp - bond.moduloHour) % (1 hours);

        require(
            withdrawalWindow >= currentOffset,
            "Tried withdrawing outside subscription cancellation time window"
        );

        bond.amount -= amount;
    }

    function calcCumulativeYieldFP(
        YieldAccumulator storage yieldAccumulator,
        uint256 timeDelta
    ) internal view returns (uint256 accumulatorFP) {
        uint256 secondsDelta = timeDelta % (1 hours);
        // linearly interpolate interest for seconds
        // FP * FP * 1 / (FP * 1) = FP
        accumulatorFP =
            yieldAccumulator.accumulatorFP +
            (yieldAccumulator.accumulatorFP *
                (yieldAccumulator.hourlyYieldFP - FP48) *
                secondsDelta) /
            (FP48 * 1 hours);

        uint256 hoursDelta = timeDelta / (1 hours);
        if (hoursDelta > 0) {
            uint256 accumulatorBeforeFP = accumulatorFP;
            for (uint256 i = 0; hoursDelta > i && MAX_HOUR_UPDATE > i; i++) {
                // FP48 * FP48 / FP48 = FP48
                accumulatorFP =
                    (accumulatorFP * yieldAccumulator.hourlyYieldFP) /
                    FP48;
            }

            // a lot of time has passed
            if (hoursDelta > MAX_HOUR_UPDATE) {
                // apply interest in non-compounding way
                accumulatorFP +=
                    ((accumulatorFP - accumulatorBeforeFP) *
                        (hoursDelta - MAX_HOUR_UPDATE)) /
                    MAX_HOUR_UPDATE;
            }
        }
    }

    /// @dev updates yield accumulators for both borrowing and lending
    /// issuer address represents a token
    function updateHourlyYield(address issuer)
        public
        returns (uint256 hourlyYield)
    {
        return
            getUpdatedHourlyYield(
                issuer,
                hourlyBondYieldAccumulators[issuer],
                RATE_UPDATE_WINDOW
            )
                .hourlyYieldFP;
    }

    /// @dev updates yield accumulators for both borrowing and lending
    function getUpdatedHourlyYield(
        address issuer,
        YieldAccumulator storage accumulator,
        uint256 window
    ) internal returns (YieldAccumulator storage) {
        uint256 lastUpdated = accumulator.lastUpdated;
        uint256 timeDelta = (block.timestamp - lastUpdated);

        if (timeDelta > window) {
            YieldAccumulator storage borrowAccumulator =
                borrowYieldAccumulators[issuer];

            accumulator.accumulatorFP = calcCumulativeYieldFP(
                accumulator,
                timeDelta
            );

            LendingMetadata storage meta = lendingMeta[issuer];

            accumulator.hourlyYieldFP = currentLendingRateFP(
                meta.totalLending,
                meta.totalBorrowed
            );
            accumulator.lastUpdated = block.timestamp;

            updateBorrowYieldAccu(borrowAccumulator);

            borrowAccumulator.hourlyYieldFP = max(
                borrowMinHourlyYield,
                FP48 +
                    (borrowingFactorPercent *
                        (accumulator.hourlyYieldFP - FP48)) /
                    100
            );
        }

        return accumulator;
    }

    function updateBorrowYieldAccu(YieldAccumulator storage borrowAccumulator)
        internal
    {
        uint256 timeDelta = block.timestamp - borrowAccumulator.lastUpdated;

        if (timeDelta > RATE_UPDATE_WINDOW) {
            borrowAccumulator.accumulatorFP = calcCumulativeYieldFP(
                borrowAccumulator,
                timeDelta
            );

            borrowAccumulator.lastUpdated = block.timestamp;
        }
    }

    function getUpdatedBorrowYieldAccuFP(address issuer)
        external
        returns (uint256)
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        updateBorrowYieldAccu(yA);
        return yA.accumulatorFP;
    }

    function viewCumulativeYieldFP(
        YieldAccumulator storage yA,
        uint256 timestamp
    ) internal view returns (uint256) {
        uint256 timeDelta = (timestamp - yA.lastUpdated);
        if (timeDelta > RATE_UPDATE_WINDOW) {
            return calcCumulativeYieldFP(yA, timeDelta);
        } else {
            return yA.accumulatorFP;
        }
    }

    function viewYearlyIncentivePer10k(address token)
        external
        view
        returns (uint256)
    {
        LendingMetadata storage meta = lendingMeta[token];
        if (
            meta.incentiveEnd < block.timestamp ||
            meta.incentiveLastUpdated > meta.incentiveEnd
        ) {
            return 0;
        } else {
            uint256 timeDelta = meta.incentiveEnd - meta.incentiveLastUpdated;

            // scale to 1 year
            return
                (10_000 * (365 days) * meta.incentiveTarget) /
                (1 + meta.totalLending * timeDelta);
        }
    }

    function updateIncentiveAllocation(LendingMetadata storage meta) internal {
        uint256 endTime = min(meta.incentiveEnd, block.timestamp);
        if (meta.incentiveTarget > 0 && endTime > meta.incentiveLastUpdated) {
            uint256 timeDelta = endTime - meta.incentiveLastUpdated;
            uint256 targetDelta =
                min(
                    meta.incentiveTarget,
                    (timeDelta * meta.incentiveTarget) /
                        (meta.incentiveEnd - meta.incentiveLastUpdated)
                );
            meta.incentiveTarget -= targetDelta;
            meta.cumulIncentiveAllocationFP +=
                (targetDelta * FP48) /
                (1 + meta.totalLending);
            meta.incentiveLastUpdated = block.timestamp;
        }
    }

    function addToTotalLending(LendingMetadata storage meta, uint256 amount)
        internal
    {
        updateIncentiveAllocation(meta);
        meta.totalLending += amount;
    }

    function subtractFromTotalLending(
        LendingMetadata storage meta,
        uint256 amount
    ) internal {
        updateIncentiveAllocation(meta);
        meta.totalLending -= amount;
    }

    function disburseIncentive(
        HourlyBond storage bond,
        LendingMetadata storage meta,
        address holder
    ) internal virtual;
}