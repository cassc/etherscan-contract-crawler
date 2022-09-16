// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IPoolManager
/// @author Angle Core Team
interface IPoolManager {
    function feeManager() external view returns (address);

    function strategyList(uint256) external view returns (address);
}