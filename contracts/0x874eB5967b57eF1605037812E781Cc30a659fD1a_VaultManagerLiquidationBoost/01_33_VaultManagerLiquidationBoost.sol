// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./VaultManager.sol";

/// @title VaultManagerLiquidationBoost
/// @author Angle Labs, Inc.
/// @notice Liquidation discount depending also on the liquidator veANGLE balance
contract VaultManagerLiquidationBoost is VaultManager {
    using SafeERC20 for IERC20;
    using Address for address;

    // =================================== SETTER ==================================

    /// @inheritdoc VaultManager
    /// @param _veBoostProxy Address which queries veANGLE balances and adjusted balances from delegation
    /// @param xBoost Threshold values of veANGLE adjusted balances
    /// @param yBoost Values of the liquidation boost at the threshold values of x
    /// @dev There are 2 modes:
    /// When boost is enabled, `xBoost` and `yBoost` should have a length of 2, but if they have a
    /// higher length contract will still work as expected. Contract will also work as expected if their
    /// length differ
    /// When boost is disabled, `_veBoostProxy` needs to be zero address and `yBoost[0]` is the base boost
    function setLiquidationBoostParameters(
        address _veBoostProxy,
        uint256[] memory xBoost,
        uint256[] memory yBoost
    ) external override onlyGovernorOrGuardian {
        if (
            (xBoost.length != yBoost.length) ||
            (yBoost[0] == 0) ||
            ((_veBoostProxy != address(0)) && (xBoost[1] <= xBoost[0] || yBoost[1] < yBoost[0]))
        ) revert InvalidSetOfParameters();
        veBoostProxy = IVeBoostProxy(_veBoostProxy);
        xLiquidationBoost = xBoost;
        yLiquidationBoost = yBoost;
        emit LiquidationBoostParametersUpdated(_veBoostProxy, xBoost, yBoost);
    }

    // ======================== OVERRIDEN VIRTUAL FUNCTIONS ========================

    /// @inheritdoc VaultManager
    function _computeLiquidationBoost(address liquidator) internal view override returns (uint256) {
        if (address(veBoostProxy) == address(0)) {
            return yLiquidationBoost[0];
        } else {
            uint256 adjustedBalance = veBoostProxy.adjusted_balance_of(liquidator);
            if (adjustedBalance >= xLiquidationBoost[1]) return yLiquidationBoost[1];
            else if (adjustedBalance <= xLiquidationBoost[0]) return yLiquidationBoost[0];
            else
                return
                    yLiquidationBoost[0] +
                    ((yLiquidationBoost[1] - yLiquidationBoost[0]) * (adjustedBalance - xLiquidationBoost[0])) /
                    (xLiquidationBoost[1] - xLiquidationBoost[0]);
        }
    }
}