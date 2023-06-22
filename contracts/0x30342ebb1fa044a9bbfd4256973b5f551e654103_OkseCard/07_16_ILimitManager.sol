// SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;

interface ILimitManager {
    function getUserLimit(address userAddr) external view returns (uint256);

    function getDailyLimit(uint256 level) external view returns (uint256);

    function getSpendAmountToday(address userAddr)
        external
        view
        returns (uint256);

    function withinLimits(address userAddr, uint256 usdAmount)
        external
        view
        returns (bool);

    function updateUserSpendAmount(address userAddr, uint256 usdAmount)
        external;
}