// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBoard {

    /// @notice extend the lockup for Board
    /// @param _amount the amount of lockup to extend
    function extendLockup(uint256 _amount) external;

    /// @notice security check for Board
    function isBoard() external pure returns (bool);
}