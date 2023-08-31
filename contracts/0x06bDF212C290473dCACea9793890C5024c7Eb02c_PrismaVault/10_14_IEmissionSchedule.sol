// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEmissionSchedule {
    event LockParametersSet(uint256 lockWeeks, uint256 lockDecayWeeks);
    event WeeklyPctScheduleSet(uint64[2][] schedule);

    function getReceiverWeeklyEmissions(
        uint256 id,
        uint256 week,
        uint256 totalWeeklyEmissions
    ) external returns (uint256);

    function getTotalWeeklyEmissions(
        uint256 week,
        uint256 unallocatedTotal
    ) external returns (uint256 amount, uint256 lock);

    function setLockParameters(uint64 _lockWeeks, uint64 _lockDecayWeeks) external returns (bool);

    function setWeeklyPctSchedule(uint64[2][] calldata _schedule) external returns (bool);

    function MAX_LOCK_WEEKS() external view returns (uint256);

    function PRISMA_CORE() external view returns (address);

    function getWeek() external view returns (uint256 week);

    function getWeeklyPctSchedule() external view returns (uint64[2][] memory);

    function guardian() external view returns (address);

    function lockDecayWeeks() external view returns (uint64);

    function lockWeeks() external view returns (uint64);

    function owner() external view returns (address);

    function vault() external view returns (address);

    function voter() external view returns (address);

    function weeklyPct() external view returns (uint64);
}