// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Errors.sol";

struct StartEndTime {
    uint64 start;
    uint64 end;
}

library TimeRangeLib {
    function isStarted(StartEndTime memory time)
        internal
        view
        returns (bool)
    {
        return time.start <= block.timestamp;
    }

    function isEnded(StartEndTime memory time)
        internal
        view
        returns (bool)
    {
        return time.end <= block.timestamp;
    }

    function isItIn(StartEndTime memory time)
        internal
        view
        returns (bool)
    {
        return isStarted(time) && !isEnded(time);
    }

    function checkStarted(StartEndTime memory time)
        internal
        view
    {
        if (!isStarted(time)) revert NotStarted();
    }

    function checkEnded(StartEndTime memory time)
        internal
        view
    {
        if (isEnded(time)) revert Ended();
    }

    function check(StartEndTime memory time)
        internal
        view
    {
        checkStarted(time);
        checkEnded(time);
    }
}