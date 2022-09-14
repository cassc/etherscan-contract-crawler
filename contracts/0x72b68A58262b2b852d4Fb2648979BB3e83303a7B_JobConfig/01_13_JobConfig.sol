// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./interfaces/ISavingsVaultViews.sol";
import "./interfaces/IJobConfig.sol";
import "./external/notional/interfaces/INotionalV2.sol";

/// @title JobConfig functions
/// @notice Contains function for configuring phuture jobs
contract JobConfig is IJobConfig, Ownable {
    /// @notice Harvesting amount specification
    HarvestingSpecification internal harvestingSpecification;
    /// @inheritdoc IJobConfig
    address public savingsVaultViews;

    constructor(address _savingsVaultViews) {
        savingsVaultViews = _savingsVaultViews;
        harvestingSpecification = HarvestingSpecification.SCALED_AMOUNT;
    }

    /// @inheritdoc IJobConfig
    function setSavingsVaultViews(address _savingsVaultViews) external onlyOwner {
        savingsVaultViews = _savingsVaultViews;
    }

    /// @inheritdoc IJobConfig
    function setHarvestingAmountSpecification(HarvestingSpecification _harvestingSpecification) external onlyOwner {
        harvestingSpecification = _harvestingSpecification;
    }

    /// @inheritdoc IJobConfig
    function getDepositedAmount(address _savingsVault) external view returns (uint) {
        if (harvestingSpecification == HarvestingSpecification.MAX_AMOUNT) {
            return type(uint).max;
        } else if (harvestingSpecification == HarvestingSpecification.MAX_DEPOSITED_AMOUNT) {
            return ISavingsVaultViews(savingsVaultViews).getMaxDepositedAmount(_savingsVault);
        } else if (harvestingSpecification == HarvestingSpecification.SCALED_AMOUNT) {
            uint amount = ISavingsVaultViews(savingsVaultViews).getMaxDepositedAmount(_savingsVault);
            if (amount == 0) {
                return amount;
            }
            return ISavingsVaultViews(savingsVaultViews).scaleAmount(_savingsVault, amount, 30, 3);
        } else {
            return 0;
        }
    }

    /// @inheritdoc IJobConfig
    function getHarvestingSpecification(uint _index) external pure returns (HarvestingSpecification) {
        if (_index == 1) return HarvestingSpecification.MAX_AMOUNT;
        if (_index == 2) return HarvestingSpecification.MAX_DEPOSITED_AMOUNT;
        if (_index == 3) return HarvestingSpecification.SCALED_AMOUNT;

        revert("JOB_CONFIG: INVALID");
    }
}