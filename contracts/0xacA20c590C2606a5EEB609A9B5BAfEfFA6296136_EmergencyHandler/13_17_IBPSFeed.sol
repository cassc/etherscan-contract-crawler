// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.8.19;

interface IBPSFeed {
    error InvalidRate();

    event UpdateRate(uint256 currentRate);

    /// @notice Returns weighted rate
    function getWeightedRate() external view returns (uint256);

    /// @notice Returns current rate
    function currentRate() external view returns (uint256);

    /// @notice Returns last timestamp the rate was set
    function lastTimestamp() external view returns (uint256);

    /// @notice Sets new rate
    /// @param rate New rate
    function updateRate(uint256 rate) external;
}