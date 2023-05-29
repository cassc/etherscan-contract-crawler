// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IAPWineFutureVault {
    function PERIOD_DURATION() external view returns (uint256);

    function getControllerAddress() external view returns (address);

    function getCurrentPeriodIndex() external view returns (uint256);

    function getFYTofPeriod(uint256) external view returns (address);

    function getIBTAddress() external view returns (address);

    function startNewPeriod() external;
}