// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "../../../tier/libraries/TierReport.sol";

library OpUpdateTimesForTierRange {
    // Stacks a report with updated times over tier range.
    // The start and end tier are taken from the low and high bits of
    // the `operand_` respectively.
    // The report to update and timestamp to update to are both
    // taken from the stack.
    function updateTimesForTierRange(
        uint256 operand_,
        uint256 stackTopLocation_
    ) internal pure returns (uint256) {
        uint256 location_;
        uint256 report_;
        uint256 startTier_ = operand_ & 0x0f; // & 00001111
        uint256 endTier_ = (operand_ >> 4) & 0x0f; // & 00001111
        uint256 timestamp_;

        assembly {
            stackTopLocation_ := sub(stackTopLocation_, 0x20)
            location_ := sub(stackTopLocation_, 0x20)
            report_ := mload(location_)
            timestamp_ := mload(stackTopLocation_)
        }

        uint256 result_ = TierReport.updateTimesForTierRange(
            report_,
            startTier_,
            endTier_,
            timestamp_
        );

        assembly {
            mstore(location_, result_)
        }
        return stackTopLocation_;
    }
}