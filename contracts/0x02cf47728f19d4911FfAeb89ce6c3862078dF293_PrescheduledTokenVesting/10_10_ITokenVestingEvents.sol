// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface ITokenVestingEvents {
    event VestingScheduleCreated(bytes32 indexed vestingScheduleId, address indexed beneficiary, uint256 indexed amount);
    event VestingScheduleExtended(bytes32 indexed vestingScheduleId, uint32 indexed extensionDuration);
    event VestingScheduleCancelled(bytes32 indexed vestingScheduleId);
    event AmountWithdrawn(uint256 indexed amount);
    event AmountReleased(bytes32 indexed vestingScheduleId, address indexed beneficiary, uint256 indexed amount);
}