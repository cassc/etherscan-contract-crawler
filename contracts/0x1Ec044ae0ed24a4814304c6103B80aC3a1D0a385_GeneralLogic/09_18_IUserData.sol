// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

interface IUserData {
    function depositReserve(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function withdrawReserve(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function depositCollateral(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function withdrawCollateral(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 currReserveSupply,
        uint256 decimals
    ) external;

    function changePosition(
        address user,
        uint256 pid,
        int256 incomingPosition,
        uint256 borrowIndex,
        uint256 decimals
    ) external;

    function getUserConfiguration(address user) external view returns (DataTypes.UserConfiguration memory);

    function getUserReserve(address user, address asset, bool claimable) external view returns (uint256);

    function getUserCollateral(address user, address asset, address reinvestment, bool claimable) external view returns (uint256);

    function getUserCollateralInternal(address user, uint256 pid, uint256 currPoolSupply, uint256 decimals) external view returns (uint256);

    function getUserPosition(address user, address asset) external view returns (int256);

    function getUserPositionInternal(address user, uint256 pid, uint256 borrowIndex, uint256 decimals) external view returns (int256);
}