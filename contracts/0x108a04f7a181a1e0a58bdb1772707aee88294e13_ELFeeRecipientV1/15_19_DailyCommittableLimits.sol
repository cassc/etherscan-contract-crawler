//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";

/// @title Daily Committable Limits storage
/// @notice Utility to manage the Daily Committable Limits in storage
library DailyCommittableLimits {
    /// @notice Storage slot of the Daily Committable Limits storage
    bytes32 internal constant DAILY_COMMITTABLE_LIMITS_SLOT =
        bytes32(uint256(keccak256("river.state.dailyCommittableLimits")) - 1);

    /// @notice The daily committable limits structure
    struct DailyCommittableLimitsStruct {
        uint128 minDailyNetCommittableAmount;
        uint128 maxDailyRelativeCommittableAmount;
    }

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The structure in storage
        DailyCommittableLimitsStruct value;
    }

    /// @notice Retrieve the Daily Committable Limits from storage
    /// @return The Daily Committable Limits
    function get() internal view returns (DailyCommittableLimitsStruct memory) {
        bytes32 slot = DAILY_COMMITTABLE_LIMITS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Set the Daily Committable Limits value in storage
    /// @param _newValue The new value to set in storage
    function set(DailyCommittableLimitsStruct memory _newValue) internal {
        bytes32 slot = DAILY_COMMITTABLE_LIMITS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value = _newValue;
    }
}