// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./IAccessControlAngle.sol";

struct LendStatus {
    string name;
    uint256 assets;
    uint256 rate;
    address add;
}

/// @title IStrategy
/// @author Inspired by Yearn with slight changes
/// @notice Interface for yield farming strategies
interface IStrategy is IAccessControlAngle {
    function estimatedAPR() external view returns (uint256);

    function poolManager() external view returns (address);

    function want() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    function withdraw(uint256 _amountNeeded) external returns (uint256 amountFreed, uint256 _loss);

    function setEmergencyExit() external;

    function addGuardian(address _guardian) external;

    function revokeGuardian(address _guardian) external;
}