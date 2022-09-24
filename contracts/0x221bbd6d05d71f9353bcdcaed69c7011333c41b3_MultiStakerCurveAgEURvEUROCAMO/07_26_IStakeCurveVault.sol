// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

interface IStakeCurveVault {
    /// @notice function to deposit a new amount
    /// @param _staker address to stake for
    /// @param _amount amount to deposit
    /// @param _earn earn or not
    function deposit(
        address _staker,
        uint256 _amount,
        bool _earn
    ) external;

    /// @notice function to withdraw
    /// @param _shares amount to withdraw
    // cautious with the withdraw fee
    function withdraw(uint256 _shares) external;

    /// @notice function to withdraw all curve LPs deposited
    function withdrawAll() external;

    function setWithdrawnFee(uint256 _newFee) external;

    function withdrawalFee() external returns (uint256);

    function accumulatedFee() external returns (uint256);
}