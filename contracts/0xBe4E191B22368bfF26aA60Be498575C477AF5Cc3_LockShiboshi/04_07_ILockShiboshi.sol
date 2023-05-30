//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILockShiboshi {
    function lockInfoOf(address user)
        external
        view
        returns (
            uint256[] memory ids,
            uint256 startTime,
            uint256 numDays,
            address ogUser
        );

    function weightOf(address user) external view returns (uint256);

    function extraShiboshiNeeded(address user, uint256 targetWeight)
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