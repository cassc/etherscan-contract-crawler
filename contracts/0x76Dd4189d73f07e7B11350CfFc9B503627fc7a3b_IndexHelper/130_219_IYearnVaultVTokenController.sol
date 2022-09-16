// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Yearn vault controller interface
/// @notice Contains logic for depositing into into the Yearn Protocol
interface IYearnVaultVTokenController {
    /// @notice Yearn Vault's address
    /// @return Returns Yearn Vault's address
    function vault() external returns (address);

    /// @notice Initializes Yearn vault controller with the given parameters
    /// @param _vToken vToken address
    /// @param _vault Yearn Vault's address
    function initialize(
        address _vToken,
        address _vault,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external;
}