// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITokenVestingV2 {
    function setManager(address manager_) external;

    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    ) external;

    function revoke(bytes32 vestingScheduleId) external;

    function withdraw(uint256 amount) external;

    function release(bytes32 vestingScheduleId, uint256 amount) external;
}