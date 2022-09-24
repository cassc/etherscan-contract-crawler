// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

interface IClaimerRewards {
    /// @notice A function to claim rewards from all the gauges supplied
    /// @param _gauges Gauges from which rewards are to be claimed
    function claimRewards(address[] calldata _gauges) external;
}