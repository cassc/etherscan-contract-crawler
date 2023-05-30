//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILockLeash {
    function lockInfoOf(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 startTime,
            uint256 numDays,
            address ogUser
        );

    function weightOf(address user) external view returns (uint256);

    function extraLeashNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256);

    function extraDaysNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256);

    function isWinner(address user) external view returns (bool);

    function unlockAt(address user) external view returns (uint256);
}