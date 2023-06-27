// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {Constants} from "./Constants.sol";

/// @title GameRegistry
/// @notice Central repository that tracks games and permissions.
/// @dev All game contracts should use extend `GameRegistryConsumer` to have consistent permissioning
contract GameRegistry is AccessControl {
    uint256[] internal stageTimes;

    // Events
    event GameRegistered(address game);
    event GameStarted(address game);
    event GameStopped(address game);
    event StageTimesSet(uint256[] stageTimes);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(Constants.GAME_ADMIN, msg.sender);

        // Initial 4 stages
        stageTimes.push(0 hours);
        stageTimes.push(2 hours);
        stageTimes.push(4 hours);
    }

    /// @notice stores enabled state for the games.
    mapping(address => bool) public games; // Address -> enabled

    /// @notice registers the game with the GameRegistry
    function registerGame(address game_) external onlyRole(Constants.GAME_ADMIN) {
        _grantRole(Constants.GAME_INSTANCE, game_);
        emit GameRegistered(game_);
    }

    /// @notice starts the game which grants it the minterRole within the THJ ecosystem and enables it.
    /// @notice enabling the game means that the game is in "progress"
    function startGame(address game_) external onlyRole(Constants.GAME_ADMIN) {
        _grantRole(Constants.MINTER, game_);
        games[game_] = true;
        emit GameStarted(game_);
    }

    /// @notice stops the game which removes the mintor role and sets enable = false
    function stopGame(address game_) external onlyRole(Constants.GAME_ADMIN) {
        _revokeRole(Constants.MINTER, game_);
        games[game_] = false;
        emit GameStopped(game_);
    }

    /**
     * Getters
     */
    function getStageTimes() external view returns (uint256[] memory) {
        return stageTimes;
    }

    /**
     * Bear Pouch setters (helper functions)
     * Can check roles directly since this is an access control
     */

    /// @notice sets the JANI role in the THJ game registry.
    function setJani(address jani_) external onlyRole(Constants.GAME_ADMIN) {
        _grantRole(Constants.JANI, jani_);
    }

    /// @notice sets the beeKeeper role in the THJ game registry.
    function setBeekeeper(address beeKeeper_) external onlyRole(Constants.GAME_ADMIN) {
        _grantRole(Constants.BEEKEEPER, beeKeeper_);
    }

    /// @notice If the stages need to be modified after this contract is created.
    function setStageTimes(uint256[] calldata _stageTimes) external onlyRole(Constants.GAME_ADMIN) {
        stageTimes = _stageTimes;
        emit StageTimesSet(stageTimes);
    }
}