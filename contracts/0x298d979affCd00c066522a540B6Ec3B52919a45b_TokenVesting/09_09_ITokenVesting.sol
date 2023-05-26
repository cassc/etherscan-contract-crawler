// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ITokenVesting {
    struct VestingSchedule {
        bool isValid;
        uint256 startTime;
        uint256 amount;
        uint16 duration;
        uint16 delay;
        uint16 weeksClaimed;
        uint256 totalClaimed;
        address recipient;
    }

    function vestingSchedules(uint256 _vestingId) external view returns (VestingSchedule memory);

    function getActiveVesting(address _recipient) external view returns (uint256);

    function addVestingSchedule(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint16 _durationInWeeks,
        uint16 _delayInWeeks
    ) external;

    function removeVestingSchedule(uint256 _vestingId) external;

    function transferOwnership(address newOwner) external;

    function totalVestingCount() external view returns (uint256);

    function totalVestingAmount() external view returns (uint256);
}