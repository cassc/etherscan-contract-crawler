// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {ITier} from "./ITier.sol";
import "./libraries/TierConstants.sol";
import "./libraries/TierReport.sol";

/// @title ReadWriteTier
/// @notice `ReadWriteTier` is a base contract that other contracts are
/// expected to inherit.
///
/// It handles all the internal accounting and state changes for `report`
/// and `setTier`.
///
/// It calls an `_afterSetTier` hook that inheriting contracts can override to
/// enforce tier requirements.
///
/// @dev ReadWriteTier can `setTier` in addition to generating reports.
/// When `setTier` is called it automatically sets the current blocks in the
/// report for the new tiers. Lost tiers are scrubbed from the report as tiered
/// addresses move down the tiers.
contract ReadWriteTier is ITier {
    /// account => reports
    mapping(address => uint256) private reports;

    /// Either fetch the report from storage or return UNINITIALIZED.
    /// @inheritdoc ITier
    function report(address account_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // Inequality here to silence slither warnings.
        return
            reports[account_] > 0
                ? reports[account_]
                : TierConstants.NEVER_REPORT;
    }

    /// Errors if the user attempts to return to the ZERO tier.
    /// Updates the report from `report` using default `TierReport` logic.
    /// Calls `_afterSetTier` that inheriting contracts SHOULD
    /// override to enforce status requirements.
    /// Emits `TierChange` event.
    /// @inheritdoc ITier
    function setTier(
        address account_,
        uint256 endTier_,
        bytes calldata data_
    ) external virtual override {
        // The user must move to at least tier 1.
        // The tier 0 status is reserved for users that have never
        // interacted with the contract.
        require(endTier_ > 0, "SET_ZERO_TIER");

        uint256 report_ = report(account_);

        uint256 startTier_ = TierReport.tierAtBlockFromReport(
            report_,
            block.number
        );

        reports[account_] = TierReport.updateReportWithTierAtBlock(
            report_,
            startTier_,
            endTier_,
            block.number
        );

        // Emit this event for ITier.
        emit TierChange(msg.sender, account_, startTier_, endTier_, data_);

        // Call the `_afterSetTier` hook to allow inheriting contracts to
        // enforce requirements.
        // The inheriting contract MUST `require` or otherwise enforce its
        // needs to rollback a bad status change.
        _afterSetTier(account_, startTier_, endTier_, data_);
    }

    /// Inheriting contracts SHOULD override this to enforce requirements.
    ///
    /// All the internal accounting and state changes are complete at
    /// this point.
    /// Use `require` to enforce additional requirements for tier changes.
    ///
    /// @param account_ The account with the new tier.
    /// @param startTier_ The tier the account had before this update.
    /// @param endTier_ The tier the account will have after this update.
    /// @param data_ Additional arbitrary data to inform update requirements.
    function _afterSetTier(
        address account_,
        uint256 startTier_,
        uint256 endTier_,
        bytes calldata data_
    ) internal virtual {} // solhint-disable-line no-empty-blocks
}