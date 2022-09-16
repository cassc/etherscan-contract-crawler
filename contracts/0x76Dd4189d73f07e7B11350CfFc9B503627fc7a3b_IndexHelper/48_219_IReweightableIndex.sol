// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.13;

/// @title Rewightable index interface
/// @notice Contains reweighting logic
interface IReweightableIndex {
    /// @notice Call index reweight process
    function reweight() external;
}