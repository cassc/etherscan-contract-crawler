// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library AuxLibrary {

    struct UnlockScheduleInternal {
        uint cycle;
        uint percentageToRelease;
        uint releaseTime;
        uint tokensPC;
        uint releaseStatus;
    }
    struct UnlockSchedule {
        uint cycle;
        uint releaseTime;
        uint tokens;
        uint releaseStatus;
    }

    struct LockerInfo {
        uint id;
        address owner;
        IERC20 token;
        uint numOfTokensLocked;
        uint numOfTokensClaimed;
    }

    struct TeamVestingRecordInternal {
        uint cycle;
        uint releaseTime;
        uint tokensPC;
        uint percentageToRelease;
        uint releaseStatus;
    }

    struct TeamVestingRecord {
        uint cycle;
        uint releaseTime;
        uint tokens;
        uint releaseStatus;
    }

    struct Participant {
        uint256 value;
        uint256 tokens;
        uint256 unclaimed;
    }
    struct ContributorsVestingRecordInternal {
        uint cycle;
        uint releaseTime;
        uint tokensPC;
        uint percentageToRelease;
    }

    struct ContributorsVestingRecord {
        uint cycle;
        uint releaseTime;
        uint tokens;
        uint releaseStatus;
    }
}