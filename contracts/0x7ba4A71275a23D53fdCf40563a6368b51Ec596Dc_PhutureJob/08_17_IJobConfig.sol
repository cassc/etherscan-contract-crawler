// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title JobConfig interface
/// @notice Describes function for configuring phuture jobs
interface IJobConfig {
    enum HarvestingSpecification {
        MAX_AMOUNT,
        MAX_DEPOSITED_AMOUNT,
        SCALED_AMOUNT
    }

    /// @notice Sets harvesting amount specification
    /// @param _harvestingSpecification Enum which specifies the harvesting amount calculation method
    function setHarvestingAmountSpecification(HarvestingSpecification _harvestingSpecification) external;

    /// @notice Gets harvesting amount specification
    /// @param _index Index of the harvesting specification
    /// @return returns harvesting specification
    function getHarvestingSpecification(uint _index) external returns (HarvestingSpecification);

    /// @notice Sets SavingsVaultViews contract
    /// @param _savingsVaultViews Address of the SavingsVaultViews
    function setSavingsVaultViews(address _savingsVaultViews) external;

    /// @notice Calculates the deposited amount based on the specification
    /// @param _savingsVault Address of the SavingsVault
    /// @return amount Amount possible to harvest
    function getDepositedAmount(address _savingsVault) external view returns (uint amount);

    /// @notice Address of the SavingsVaultViews contract
    /// @return Returns address of the SavingsVaultViews contract
    function savingsVaultViews() external view returns (address);
}