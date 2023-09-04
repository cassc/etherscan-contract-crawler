//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @dev Collateral info for price oracle
struct Collateral {
    address tokenAddress;
    uint256 initialCollateralRatio;
    uint256 maintenanceRatio;
    uint256 liquidatedDamage;
}