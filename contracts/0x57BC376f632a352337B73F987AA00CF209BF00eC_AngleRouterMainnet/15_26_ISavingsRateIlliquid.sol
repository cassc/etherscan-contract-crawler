// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title ISavingsRateIlliquid
/// @author Angle Core Team
/// @notice Interface for Angle's `SavingsRateIlliquid` contracts
interface ISavingsRateIlliquid {
    function claimRedeem(address receiver, address[] memory strategiesToClaim) external returns (uint256 totalOwed);

    function prepareRedeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256);
}