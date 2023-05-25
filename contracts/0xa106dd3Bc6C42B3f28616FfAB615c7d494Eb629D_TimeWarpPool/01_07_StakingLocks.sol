//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract StakingLocks {
    enum LockType { NULL, HOURS1, DAYS30, DAYS180, DAYS365, DAYS730}

    LockType[5] lockTypes = [LockType.HOURS1, LockType.DAYS30, LockType.DAYS180, LockType.DAYS365, LockType.DAYS730];

    struct LockData {
        uint32 period;
        uint8 multiplicator; // 11 factor is equal 1.1
    }

    mapping(LockType => LockData) public locks; // All our locks

    function _initLocks() internal {
        locks[LockType.HOURS1] = LockData(1 hours, 10);
        locks[LockType.DAYS30] = LockData(30 days, 12);
        locks[LockType.DAYS180] = LockData(180 days, 13);
        locks[LockType.DAYS365] = LockData(365 days, 15);
        locks[LockType.DAYS730] = LockData(730 days, 20);
    }
}