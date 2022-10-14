// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IDfxMiddlemanGauge
/// @author Forked from contracts developed by Angle and adapted by DFX
/// - IAngleMiddlemanGauge.sol (https://github.com/AngleProtocol/angle-core/blob/main/contracts/interfaces/IAngleMiddlemanGauge.sol)
/// @notice Interface for the `DfxMiddleman` contract
interface IDfxMiddlemanGauge {
    function notifyReward(address gauge, uint256 amount) external;
}