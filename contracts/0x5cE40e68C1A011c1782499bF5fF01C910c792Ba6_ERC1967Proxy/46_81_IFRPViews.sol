// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./IFRPViewer.sol";

/// @title Fixed rate product vault helper view functions interface
/// @notice Describes helper view functions
interface IFRPViews {
    /// @notice Spot annual percentage yield(APY) of the FRP vault
    /// @param _FRP Address of the vault
    /// @return Returns APY of the vault with the precision of 1,000,000,000 units i.e. 37264168 equals to 3.7264168%
    function getAPY(IFRPViewer _FRP) external view returns (uint);

    /// @notice Checks if vault can harvest max amount (asset in the vault + redeemed matured fCash)
    /// @param _FRP Address of the vault
    /// @return canHarvest true if it can harvest max deposited amount available
    /// @return maxDepositedAmount max deposited amount available
    function canHarvestMaxDepositedAmount(address _FRP)
        external
        view
        returns (bool canHarvest, uint maxDepositedAmount);

    /// @notice Checks if vault can harvest amount
    /// @param _amount Amount to check
    /// @param _FRP Address of the vault
    /// @return canHarvest true if it can harvest
    function canHarvestAmount(uint _amount, address _FRP) external view returns (bool canHarvest);

    /// @notice Max amount which can be deposited onto Notional
    /// @param _FRP Address of the vault
    /// @return maxDepositedAmount  max deposited amount available
    function getMaxDepositedAmount(address _FRP) external view returns (uint maxDepositedAmount);
}