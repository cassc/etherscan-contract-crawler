//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./VestingSchedules.1.sol";

/// @title VestingSchedulesV2 Storage
/// @notice Utility to manage VestingSchedulesV2 in storage
library VestingSchedulesV2 {
    /// @notice Storage slot of the Vesting Schedules (note the slot is different from v1)
    bytes32 internal constant VESTING_SCHEDULES_SLOT =
        bytes32(uint256(keccak256("erc20VestableVotes.state.v2.schedules")) - 1);

    struct VestingSchedule {
        // start time of the vesting period
        uint64 start;
        // date at which the vesting is ended
        // initially it is equal to start+duration then to revoke date in case of revoke
        uint64 end;
        // duration before which first tokens gets ownable
        uint32 cliffDuration;
        // duration before tokens gets unlocked. can exceed the duration of the vesting chedule
        uint32 lockDuration;
        // duration of the entire vesting (sum of all vesting period durations)
        uint32 duration;
        // duration of a single period of vesting
        uint32 periodDuration;
        // amount of tokens granted by the vesting schedule
        uint256 amount;
        // creator of the token vesting
        address creator;
        // beneficiary of tokens after they are releaseVestingScheduled
        address beneficiary;
        // whether the schedule can be revoked
        bool revocable;
        // amount of released tokens
        uint256 releasedAmount;
    }

    /// @notice The structure at the storage slot
    struct SlotVestingSchedule {
        /// @custom:attribute Array containing all the vesting schedules
        VestingSchedule[] value;
    }

    /// @notice The VestingSchedule was not found
    /// @param index vesting schedule index
    error VestingScheduleNotFound(uint256 index);

    /// @notice Retrieve the vesting schedule in storage
    /// @param _index index of the vesting schedule
    /// @return the vesting schedule
    function get(uint256 _index) internal view returns (VestingSchedule storage) {
        bytes32 slot = VESTING_SCHEDULES_SLOT;

        SlotVestingSchedule storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        if (r.value.length <= _index) {
            revert VestingScheduleNotFound(_index);
        }

        return r.value[_index];
    }

    /// @notice Get vesting schedule count in storage
    /// @return The count of vesting schedule in storage
    function getCount() internal view returns (uint256) {
        bytes32 slot = VESTING_SCHEDULES_SLOT;

        SlotVestingSchedule storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value.length;
    }

    /// @notice Add a new vesting schedule in storage
    /// @param _newSchedule new vesting schedule to create
    /// @return The size of the vesting schedule array after the operation
    function push(VestingSchedule memory _newSchedule) internal returns (uint256) {
        bytes32 slot = VESTING_SCHEDULES_SLOT;

        SlotVestingSchedule storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value.push(_newSchedule);

        return r.value.length;
    }

    /// @notice Migrate a VestingSchedule from v1 to v2
    /// @notice Takes a VestingSchedule in v1 format in stores it in v2 format
    /// @param _index of the schedule in v1 to be migrated
    /// @param _releasedAmount The released amount to keep in storage
    /// @return The index of the created schedule in v2 format
    function migrateVestingScheduleFromV1(uint256 _index, uint256 _releasedAmount) internal returns (uint256) {
        VestingSchedulesV1.VestingSchedule memory scheduleV1 = VestingSchedulesV1.get(_index);
        VestingSchedulesV2.VestingSchedule memory scheduleV2 = VestingSchedulesV2.VestingSchedule({
            start: scheduleV1.start,
            end: scheduleV1.end,
            lockDuration: scheduleV1.lockDuration,
            cliffDuration: scheduleV1.cliffDuration,
            duration: scheduleV1.duration,
            periodDuration: scheduleV1.periodDuration,
            amount: scheduleV1.amount,
            creator: scheduleV1.creator,
            beneficiary: scheduleV1.beneficiary,
            revocable: scheduleV1.revocable,
            releasedAmount: _releasedAmount
        });

        return push(scheduleV2) - 1;
    }
}