// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title YieldYak vault controller interface
/// @notice Contains logic for depositing into into the YieldYak Protocol
interface IYakStrategyController {
    /// @notice YieldYak strategy address
    /// @return Returns YieldYak strategy address
    function strategy() external returns (address);

    /// @notice Initializes YieldYak vault controller with the given parameters
    /// @param _vToken vToken address
    /// @param _strategy YieldYak strategy's address
    function initialize(
        address _vToken,
        address _strategy,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external;
}