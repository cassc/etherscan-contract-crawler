//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Global unlock schedule activation storage
/// @notice Utility to manage the global unlock schedule activation mapping in storage
/// @notice The global unlock schedule releases 1/24th of the total scheduled amount every month after the local lock end
library IgnoreGlobalUnlockSchedule {
    /// @notice Storage slot of the global unlock schedule activation mapping
    bytes32 internal constant GLOBAL_UNLOCK_ACTIVATION_SLOT =
        bytes32(uint256(keccak256("tlc.state.globalUnlockScheduleActivation")) - 1);

    /// @notice Structure stored in storage slot
    struct Slot {
        /// @custom:attribute Mapping keeping track of activation per schedule
        mapping(uint256 => bool) value;
    }

    /// @notice Retrieve the global unlock schedule activation value of a schedule, true if the global lock should be ignored
    /// @param _scheduleId The schedule id
    /// @return The global unlock activation value
    function get(uint256 _scheduleId) internal view returns (bool) {
        bytes32 slot = GLOBAL_UNLOCK_ACTIVATION_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_scheduleId];
    }

    /// @notice Sets the global unlock schedule activation value of a schedule
    /// @param _scheduleId The id of the schedule to modify
    /// @param _ignoreGlobalUnlock The value to set, true if the global lock should be ignored
    function set(uint256 _scheduleId, bool _ignoreGlobalUnlock) internal {
        bytes32 slot = GLOBAL_UNLOCK_ACTIVATION_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_scheduleId] = _ignoreGlobalUnlock;
    }
}