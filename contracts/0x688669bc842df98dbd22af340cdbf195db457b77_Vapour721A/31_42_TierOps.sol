// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";
import "../../../tier/libraries/TierReport.sol";
import "../../../tier/libraries/TierwiseCombine.sol";

/// @dev Opcode to call `report` on an `ITier` contract.
uint256 constant OPCODE_REPORT = 0;
/// @dev Opcode to stack a report that has never been held for all tiers.
uint256 constant OPCODE_NEVER = 1;
/// @dev Opcode to stack a report that has always been held for all tiers.
uint256 constant OPCODE_ALWAYS = 2;
/// @dev Opcode to calculate the tierwise diff of two reports.
uint256 constant OPCODE_SATURATING_DIFF = 3;
/// @dev Opcode to update the blocks over a range of tiers for a report.
uint256 constant OPCODE_UPDATE_BLOCKS_FOR_TIER_RANGE = 4;
/// @dev Opcode to tierwise select the best block lte a reference block.
uint256 constant OPCODE_SELECT_LTE = 5;
/// @dev Number of provided opcodes for `TierOps`.
uint256 constant TIER_OPS_LENGTH = 6;

/// @title TierOps
/// @notice RainVM opcode pack to operate on tier reports.
/// The opcodes all map to functions from `ITier` and associated libraries such
/// as `TierConstants`, `TierwiseCombine`, and `TierReport`. For each, the
/// order of consumed values on the stack corresponds to the order of arguments
/// to interface/library functions.
library TierOps {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view {
        unchecked {
            require(opcode_ < TIER_OPS_LENGTH, "MAX_OPCODE");
            uint256 baseIndex_;
            // Stack the report returned by an `ITier` contract.
            // Top two stack vals are used as `ITier` contract and address
            // to check the report for.
            if (opcode_ == OPCODE_REPORT) {
                state_.stackIndex -= 1;
                baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = ITier(
                    address(uint160(state_.stack[baseIndex_]))
                ).report(address(uint160(state_.stack[baseIndex_ + 1])));
            }
            // Stack a report that has never been held at any tier.
            else if (opcode_ == OPCODE_NEVER) {
                state_.stack[state_.stackIndex] = TierConstants.NEVER_REPORT;
                state_.stackIndex++;
            }
            // Stack a report that has always been held at every tier.
            else if (opcode_ == OPCODE_ALWAYS) {
                state_.stack[state_.stackIndex] = TierConstants.ALWAYS;
                state_.stackIndex++;
            }
            // Stack the tierwise saturating subtraction of two reports.
            // If the older report is newer than newer report the result will
            // be `0`, else a tierwise diff in blocks will be obtained.
            // The older and newer report are taken from the stack.
            else if (opcode_ == OPCODE_SATURATING_DIFF) {
                state_.stackIndex -= 2;
                baseIndex_ = state_.stackIndex;
                uint256 newerReport_ = state_.stack[baseIndex_];
                uint256 olderReport_ = state_.stack[baseIndex_ + 1];
                state_.stack[baseIndex_] = TierwiseCombine.saturatingSub(
                    newerReport_,
                    olderReport_
                );
                state_.stackIndex++;
            }
            // Stacks a report with updated blocks over tier range.
            // The start and end tier are taken from the low and high bits of
            // the `operand_` respectively.
            // The report to update and block number to update to are both
            // taken from the stack.
            else if (opcode_ == OPCODE_UPDATE_BLOCKS_FOR_TIER_RANGE) {
                uint256 startTier_ = operand_ & 0x0f; // & 00001111
                uint256 endTier_ = (operand_ >> 4) & 0x0f; // & 00001111
                state_.stackIndex -= 2;
                baseIndex_ = state_.stackIndex;
                uint256 report_ = state_.stack[baseIndex_];
                uint256 blockNumber_ = state_.stack[baseIndex_ + 1];
                state_.stack[baseIndex_] = TierReport.updateBlocksForTierRange(
                    report_,
                    startTier_,
                    endTier_,
                    blockNumber_
                );
                state_.stackIndex++;
            }
            // Stacks the result of a `selectLte` combinator.
            // All `selectLte` share the same stack and argument handling.
            // Takes the `logic_` and `mode_` from the `operand_` high bits.
            // `logic_` is the highest bit.
            // `mode_` is the 2 highest bits after `logic_`.
            // The other bits specify how many values to take from the stack
            // as reports to compare against each other and the block number.
            else if (opcode_ == OPCODE_SELECT_LTE) {
                uint256 logic_ = operand_ >> 7;
                uint256 mode_ = (operand_ >> 5) & 0x3; // & 00000011
                uint256 reportsLength_ = operand_ & 0x1F; // & 00011111

                // Need one more than reports length to include block number.
                state_.stackIndex -= reportsLength_ + 1;
                baseIndex_ = state_.stackIndex;
                uint256 cursor_ = baseIndex_;

                uint256[] memory reports_ = new uint256[](reportsLength_);
                for (uint256 a_ = 0; a_ < reportsLength_; a_++) {
                    reports_[a_] = state_.stack[cursor_];
                    cursor_++;
                }
                uint256 blockNumber_ = state_.stack[cursor_];

                state_.stack[baseIndex_] = TierwiseCombine.selectLte(
                    reports_,
                    blockNumber_,
                    logic_,
                    mode_
                );
                state_.stackIndex++;
            }
        }
    }
}