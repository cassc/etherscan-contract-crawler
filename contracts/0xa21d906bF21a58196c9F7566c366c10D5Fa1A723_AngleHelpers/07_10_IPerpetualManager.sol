// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IPerpetualManager
/// @author Angle Core Team
interface IPerpetualManager {
    function totalHedgeAmount() external view returns (uint256);

    function maintenanceMargin() external view returns (uint64);

    function maxLeverage() external view returns (uint64);

    function targetHAHedge() external view returns (uint64);

    function limitHAHedge() external view returns (uint64);

    function lockTime() external view returns (uint64);

    function haBonusMalusDeposit() external view returns (uint64);

    function haBonusMalusWithdraw() external view returns (uint64);

    function xHAFeesDeposit(uint256) external view returns (uint64);

    function yHAFeesDeposit(uint256) external view returns (uint64);

    function xHAFeesWithdraw(uint256) external view returns (uint64);

    function yHAFeesWithdraw(uint256) external view returns (uint64);
}