// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title IPhutureJob interface
/// @notice Exposes functions for state management of Phuture Job contract
interface IPhutureJob {
    /// @notice Sets Job config address
    /// @param _jobConfig Address of job config contract
    function setJobConfig(address _jobConfig) external;

    /// @notice Job config address
    /// @return Returns address of jobConfig contract
    function jobConfig() external view returns (address);
}