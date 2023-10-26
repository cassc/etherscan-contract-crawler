//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../state/tlc/VestingSchedules.2.sol";
import "../state/tlc/IgnoreGlobalUnlockSchedule.sol";

struct VestingScheduleMigration {
    // number of consecutive schedules to migrate with the same parameters
    uint8 scheduleCount;
    // The new lock duration
    uint32 newLockDuration;
    // if != 0, the new start value
    uint64 newStart;
    // if != 0, the new end value
    uint64 newEnd;
    // set cliff to 0 if true
    bool setCliff;
    // if true set vesting duration to 86400
    bool setDuration;
    // if true set vesting period duration to 86400
    bool setPeriodDuration;
    // if true schedule will not be subject to global unlock schedule
    bool ignoreGlobalUnlock;
}

uint256 constant OCTOBER_16_2024 = 1729036800;

contract TlcMigration {
    error CliffTooLong(uint256 i);
    error WrongUnlockDate(uint256 i);
    error WrongEnd(uint256 i);

    function migrate() external {
        VestingScheduleMigration[] memory migrations = new VestingScheduleMigration[](30);
        // 0 -> 6
        migrations[0] = VestingScheduleMigration({
            scheduleCount: 7,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 75772800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 7
        migrations[1] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 70329600,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 8
        migrations[2] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 65491200,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 9 -> 12
        migrations[3] = VestingScheduleMigration({
            scheduleCount: 4,
            newStart: 0,
            newEnd: 1656720000,
            newLockDuration: 72403200,
            setCliff: true,
            setDuration: true,
            setPeriodDuration: true,
            ignoreGlobalUnlock: false
        });
        // 13
        migrations[4] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 67046400,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 14
        migrations[5] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 56505600,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 15
        migrations[6] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 58233600,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 16
        migrations[7] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 57974400,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 17
        migrations[8] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 53740800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // 18
        migrations[9] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 75772800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 19
        migrations[10] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 49474800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 20
        migrations[11] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 75772800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 21
        migrations[12] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 49474800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 22
        migrations[13] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 75772800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 23
        migrations[14] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 49474800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 24 -> 26
        migrations[15] = VestingScheduleMigration({
            scheduleCount: 3,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 75772800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 27
        migrations[16] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 70329600,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 28 -> 29
        migrations[17] = VestingScheduleMigration({
            scheduleCount: 2,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 50371200,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 30
        migrations[18] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 50716800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // 31
        migrations[19] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 50803200,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // 32
        migrations[20] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 50889600,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // 33
        migrations[21] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 50716800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // 34 -> 35
        migrations[22] = VestingScheduleMigration({
            scheduleCount: 2,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 50889600,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // 36 -> 60
        migrations[23] = VestingScheduleMigration({
            scheduleCount: 25,
            newStart: 1686175200,
            newEnd: 1686261600,
            newLockDuration: 42861600,
            setCliff: false,
            setDuration: true,
            setPeriodDuration: true,
            ignoreGlobalUnlock: false
        });
        // 61
        migrations[24] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 40953600,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 62
        migrations[25] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 48729600,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: false
        });
        // 63
        migrations[26] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 41644800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // 64
        migrations[27] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 47001600,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // 65
        migrations[28] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 45014400,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // 66
        migrations[29] = VestingScheduleMigration({
            scheduleCount: 1,
            newStart: 0,
            newEnd: 0,
            newLockDuration: 38188800,
            setCliff: false,
            setDuration: false,
            setPeriodDuration: false,
            ignoreGlobalUnlock: true
        });
        // All schedules covered

        uint256 index = 0;
        for (uint256 i = 0; i < migrations.length; i++) {
            VestingScheduleMigration memory migration = migrations[i];
            for (uint256 j = 0; j < migration.scheduleCount; j++) {
                VestingSchedulesV2.VestingSchedule storage sch = VestingSchedulesV2.get(index);

                bool isRevoked = false;
                if (sch.start + sch.duration != sch.end) {
                    isRevoked = true;
                }
                // Modifications
                sch.lockDuration = migration.newLockDuration;
                if (migration.newStart != 0) {
                    sch.start = migration.newStart;
                }
                if (migration.newEnd != 0) {
                    sch.end = migration.newEnd;
                }
                if (migration.setCliff) {
                    sch.cliffDuration = 0;
                }
                if (migration.setDuration) {
                    sch.duration = 86400;
                }
                if (migration.setPeriodDuration) {
                    sch.periodDuration = 86400;
                }
                if (migration.ignoreGlobalUnlock) {
                    IgnoreGlobalUnlockSchedule.set(index, true);
                }

                // Post effects checks
                // check cliff is not longer than duration
                if (sch.cliffDuration > sch.duration) {
                    revert CliffTooLong(index);
                }
                // sanity checks on non revoked schedules
                if (!isRevoked && (sch.end != sch.start + sch.duration)) {
                    revert WrongEnd(index);
                }
                // check all the schedules are locked until unix : 1729036800
                if (sch.start + sch.lockDuration != OCTOBER_16_2024) {
                    revert WrongUnlockDate(index);
                }

                index += 1;
            }
        }
    }
}