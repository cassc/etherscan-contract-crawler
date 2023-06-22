// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./ISavingsVaultViewer.sol";
import { IWrappedfCashComplete } from "../external/notional/interfaces/IWrappedfCash.sol";
import "../external/notional/interfaces/INotionalV2.sol";

/// @title Fixed rate product vault helper view functions interface
/// @notice Describes helper view functions
interface ISavingsVaultViews {
    /// @notice Base point number
    /// @return Returns base point number
    function BP() external view returns (uint16);

    /// @notice Spot annual percentage yield(APY) of the Savings Vault
    /// @param _savingsVault Address of the vault
    /// @return Returns APY of the vault with the precision of 1,000,000,000 units i.e. 37264168 equals to 3.7264168%
    function getAPY(ISavingsVaultViewer _savingsVault) external view returns (uint);

    /// @notice Max amount which can be deposited onto Notional
    /// @param _savingsVault Address of the vault
    /// @return maxDepositedAmount  max deposited amount available
    function getMaxDepositedAmount(address _savingsVault) external view returns (uint maxDepositedAmount);

    /// @notice Scales down the passed amount if there is price slippage.
    /// @param _savingsVault Address of the vault
    /// @param _amount Amount to scale down
    /// @param _percentage Percentage of initial amount to scale down during each step in BP.
    /// @param _steps Number of iterations for scaling down.
    /// @return Scaled amount
    function scaleAmount(
        address _savingsVault,
        uint _amount,
        uint _percentage,
        uint _steps
    ) external view returns (uint);

    /// @notice Scales down the passed amount if there is price slippage.
    /// @param _savingsVault Address of the vault
    /// @param _amount Amount to scale down
    /// @param _steps Steps to scaled down with binary search
    /// @return Scaled amount
    function scaleWithBinarySearch(
        address _savingsVault,
        uint _amount,
        uint _steps
    ) external view returns (uint);

    /// @notice Returns highest yiled market parameters
    /// @param _savingsVault Address of the vault
    /// @return maturity Maturity timestamp
    /// @return minImpliedRate Annualized oracle interest rate scaled by maxLoss for the vault
    /// @return currencyId Id of the currency on Notional
    /// @return calculationViews Views contract from Notional
    function getHighestYieldMarketParameters(address _savingsVault)
        external
        view
        returns (
            uint maturity,
            uint32 minImpliedRate,
            uint16 currencyId,
            INotionalV2 calculationViews
        );
}