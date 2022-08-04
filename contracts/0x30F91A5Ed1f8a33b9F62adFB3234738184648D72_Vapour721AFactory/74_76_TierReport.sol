// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {ITierV2} from "../ITierV2.sol";
import "./TierConstants.sol";

/// @title TierReport
/// @notice `TierReport` implements several pure functions that can be
/// used to interface with reports.
/// - `tierAtTimeFromReport`: Returns the highest status achieved relative to
/// a block timestamp and report. Statuses gained after that block are ignored.
/// - `tierTime`: Returns the timestamp that a given tier has been held
/// since according to a report.
/// - `truncateTiersAbove`: Resets all the tiers above the reference tier.
/// - `updateTimesForTierRange`: Updates a report with a timestamp for every
///    tier in a range.
/// - `updateReportWithTierAtTime`: Updates a report to a new tier.
/// @dev Utilities to consistently read, write and manipulate tiers in reports.
/// The low-level bit shifting can be difficult to get right so this
/// factors that out.
library TierReport {
    /// Enforce upper limit on tiers so we can do unchecked math.
    /// @param tier_ The tier to enforce bounds on.
    modifier maxTier(uint256 tier_) {
        require(tier_ <= TierConstants.MAX_TIER, "MAX_TIER");
        _;
    }

    /// Returns the highest tier achieved relative to a block timestamp
    /// and report.
    ///
    /// Note that typically the report will be from the _current_ contract
    /// state, i.e. `block.timestamp` but not always. Tiers gained after the
    /// reference time are ignored.
    ///
    /// When the `report` comes from a later block than the `timestamp_` this
    /// means the user must have held the tier continuously from `timestamp_`
    /// _through_ to the report block.
    /// I.e. NOT a snapshot.
    ///
    /// @param report_ A report as per `ITierV2`.
    /// @param timestamp_ The timestamp to check the tiers against.
    /// @return tier_ The highest tier held since `timestamp_` as per `report`.
    function tierAtTimeFromReport(uint256 report_, uint256 timestamp_)
        internal
        pure
        returns (uint256 tier_)
    {
        unchecked {
            for (tier_ = 0; tier_ < 8; tier_++) {
                if (uint32(uint256(report_ >> (tier_ * 32))) > timestamp_) {
                    break;
                }
            }
        }
    }

    /// Returns the timestamp that a given tier has been held since from a
    /// report.
    ///
    /// The report MUST encode "never" as 0xFFFFFFFF. This ensures
    /// compatibility with `tierAtTimeFromReport`.
    ///
    /// @param report_ The report to read a timestamp from.
    /// @param tier_ The Tier to read the timestamp for.
    /// @return timestamp_ The timestamp the tier has been held since.
    function reportTimeForTier(uint256 report_, uint256 tier_)
        internal
        pure
        maxTier(tier_)
        returns (uint256 timestamp_)
    {
        unchecked {
            // ZERO is a special case. Everyone has always been at least ZERO,
            // since block 0.
            if (tier_ == 0) {
                return 0;
            }

            uint256 offset_ = (tier_ - 1) * 32;
            timestamp_ = uint256(uint32(uint256(report_ >> offset_)));
        }
    }

    /// Resets all the tiers above the reference tier to 0xFFFFFFFF.
    ///
    /// @param report_ Report to truncate with high bit 1s.
    /// @param tier_ Tier to truncate above (exclusive).
    /// @return Truncated report.
    function truncateTiersAbove(uint256 report_, uint256 tier_)
        internal
        pure
        maxTier(tier_)
        returns (uint256)
    {
        unchecked {
            uint256 offset_ = tier_ * 32;
            uint256 mask_ = (TierConstants.NEVER_REPORT >> offset_) << offset_;
            return report_ | mask_;
        }
    }

    /// Updates a report with a timestamp for a given tier.
    /// More gas efficient than `updateTimesForTierRange` if only a single
    /// tier is being modified.
    /// The tier at/above the given tier is updated. E.g. tier `0` will update
    /// the time for tier `1`.
    /// @param report_ Report to use as the baseline for the updated report.
    /// @param tier_ The tier level to update.
    /// @param timestamp_ The new block number for `tier_`.
    /// @return updatedReport_ The newly updated `report_`.
    function updateTimeAtTier(
        uint256 report_,
        uint256 tier_,
        uint256 timestamp_
    ) internal pure maxTier(tier_) returns (uint256 updatedReport_) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            updatedReport_ =
                (report_ &
                    ~uint256(uint256(TierConstants.NEVER_TIME) << offset_)) |
                uint256(timestamp_ << offset_);
        }
    }

    /// Updates a report with a block number for every tier in a range.
    ///
    /// Does nothing if the end status is equal or less than the start tier.
    /// @param report_ The report to update.
    /// @param startTier_ The tier at the start of the range (exclusive).
    /// @param endTier_ The tier at the end of the range (inclusive).
    /// @param timestamp_ The timestamp to set for every tier in the range.
    /// @return updatedReport_ The updated report.
    function updateTimesForTierRange(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure maxTier(endTier_) returns (uint256 updatedReport_) {
        unchecked {
            uint256 offset_;
            for (uint256 i_ = startTier_; i_ < endTier_; i_++) {
                offset_ = i_ * 32;
                report_ =
                    (report_ &
                        ~uint256(
                            uint256(TierConstants.NEVER_TIME) << offset_
                        )) |
                    uint256(timestamp_ << offset_);
            }
            updatedReport_ = report_;
        }
    }

    /// Updates a report to a new status.
    ///
    /// Internally dispatches to `truncateTiersAbove` and
    /// `updateBlocksForTierRange`.
    /// The dispatch is based on whether the new tier is above or below the
    /// current tier.
    /// The `startTier_` MUST match the result of `tierAtBlockFromReport`.
    /// It is expected the caller will know the current tier when
    /// calling this function and need to do other things in the calling scope
    /// with it.
    ///
    /// @param report_ The report to update.
    /// @param startTier_ The tier to start updating relative to. Data above
    /// this tier WILL BE LOST so probably should be the current tier.
    /// @param endTier_ The new highest tier held, at the given block number.
    /// @param timestamp_ The timestamp_ to update the highest tier to, and
    /// intermediate tiers from `startTier_`.
    /// @return updatedReport_ The updated report.
    function updateReportWithTierAtTime(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure returns (uint256 updatedReport_) {
        updatedReport_ = endTier_ < startTier_
            ? truncateTiersAbove(report_, endTier_)
            : updateTimesForTierRange(
                report_,
                startTier_,
                endTier_,
                timestamp_
            );
    }
}