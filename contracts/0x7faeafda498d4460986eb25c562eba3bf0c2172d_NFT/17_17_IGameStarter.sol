// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/// @title Define a simple interface for starting the game.
/// @dev to be implemented for the GameController.
interface IGameStarter {
    /// @notice start the actual trading game.
    /// @return boolean if everything went successfully.
    function startGame() external returns (bool);
}