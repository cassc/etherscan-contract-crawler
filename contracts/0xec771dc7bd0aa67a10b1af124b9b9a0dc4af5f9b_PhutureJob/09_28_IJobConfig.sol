// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./ISavingsVaultViews.sol";

/// @title JobConfig interface
/// @notice Describes function for configuring phuture jobs
interface IJobConfig {
    enum HarvestingSpecification {
        MAX_AMOUNT,
        MAX_DEPOSITED_AMOUNT,
        SCALED_AMOUNT,
        BINARY_SEARCH_SCALED_AMOUNT
    }

    /// @notice Number of steps for scaling
    /// @return Returns number of steps for scaling
    function SCALING_STEPS() external view returns (uint);

    /// @notice Percentage scaled each step in BP
    /// @return Returns percentage scaled each step in BP
    function SCALING_PERCENTAGE() external view returns (uint);

    /// @notice Steps to scale with binary search
    /// @return Returns steps to scale with binary search
    function SCALING_STEPS_BINARY_SEARCH() external view returns (uint);

    /// @notice Sets harvesting amount specification
    /// @param _harvestingSpecification Enum which specifies the harvesting amount calculation method
    function setHarvestingAmountSpecification(HarvestingSpecification _harvestingSpecification) external;

    /// @notice Gets harvesting amount specification
    /// @return returns harvesting specification
    function harvestingSpecification() external returns (HarvestingSpecification);

    /// @notice Sets SavingsVaultViews contract
    /// @param _savingsVaultViews Address of the SavingsVaultViews
    function setSavingsVaultViews(ISavingsVaultViews _savingsVaultViews) external;

    /// @notice Calculates the deposited amount based on the specification
    /// @param _savingsVault Address of the SavingsVault
    /// @return amount Amount possible to harvest
    function getDepositedAmount(address _savingsVault) external view returns (uint amount);

    /// @notice Address of the SavingsVaultViews contract
    /// @return Returns address of the SavingsVaultViews contract
    function savingsVaultViews() external view returns (ISavingsVaultViews);
}