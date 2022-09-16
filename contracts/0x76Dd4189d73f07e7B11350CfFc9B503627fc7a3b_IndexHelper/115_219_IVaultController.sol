// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Vault controller interface
/// @notice Contains common logic for VaultControllers
interface IVaultController {
    event Deposit(uint amount);
    event Withdraw(uint amount);
    event SetDepositInfo(uint _targetDepositPercentageInBP, uint percentageInBPPerStep, uint stepDuration);

    /// @notice Sets deposit info for the vault
    /// @param _targetDepositPercentageInBP Target deposit percentage
    /// @param _percentageInBPPerStep Deposit percentage per step
    /// @param _stepDuration Deposit interval duration
    function setDepositInfo(
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external;

    /// @notice Deposits asset using vault controller
    function deposit() external;

    /// @notice Withdraws asset using vault controller
    function withdraw() external;

    /// @notice vToken's asset address
    /// @return Returns vToken's asset address
    function asset() external view returns (address);

    /// @notice vToken address
    /// @return Returns vToken address
    function vToken() external view returns (address);

    /// @notice Index Registry address
    /// @return Returns Index Registry address
    function registry() external view returns (address);

    /// @notice Expected amount of asset that can be withdrawn using vault controller
    /// @return Returns expected amount of token that can be withdrawn using vault controller
    function expectedWithdrawableAmount() external view returns (uint);

    /// @notice Total percentage of token amount that will be deposited using vault controller to earn interest
    /// @return Returns total percentage of token amount that will be deposited using vault controller to earn interest
    function targetDepositPercentageInBP() external view returns (uint16);

    /// @notice Percentage of token amount that will be deposited using vault controller per deposit step
    /// @return Returns percentage of token amount that will be deposited using vault controller per deposit step
    function percentageInBPPerStep() external view returns (uint16);

    /// @notice Deposit interval duration
    /// @return Returns deposit interval duration
    /// @dev    vToken deposit is updated gradually at defined intervals (steps). Every interval has time duration defined.
    ///         Deposited amount is calculated as timeElapsedFromLastDeposit / stepDuration * percentageInBPPerStep
    function stepDuration() external view returns (uint32);

    /// @notice Calculates deposit amount
    /// @param _currentDepositedPercentageInBP Current deposited percentage
    /// @return Returns deposit amount
    function calculatedDepositAmount(uint _currentDepositedPercentageInBP) external view returns (uint);
}