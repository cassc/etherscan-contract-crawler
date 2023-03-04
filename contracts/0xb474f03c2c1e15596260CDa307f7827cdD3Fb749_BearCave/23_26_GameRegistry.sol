// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {Constants} from "./GameLib.sol";

/// @title GameRegistry
/// @notice Central repository that tracks games and permissions.
/// @dev All game contracts should use extend `GameRegistryConsumer` to have consistent permissioning
contract GameRegistry is AccessControl {
    struct Game {
        bool enabled;
    }

    uint256[] public stageTimes;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(Constants.GAME_ADMIN, msg.sender);

        // Initial 4 stages
        stageTimes.push(0 hours);
        stageTimes.push(24 hours);
        stageTimes.push(48 hours);
        stageTimes.push(72 hours);
    }

    mapping(address => Game) public games;

    function registerGame(address game_) external onlyRole(Constants.GAME_ADMIN) {
        _grantRole(Constants.GAME_INSTANCE, game_);
        games[game_] = Game(true);
    }

    function startGame(address game_) external onlyRole(Constants.GAME_ADMIN) {
        _grantRole(Constants.MINTER, game_);
    }

    function stopGame(address game_) external onlyRole(Constants.GAME_ADMIN) {
        _revokeRole(Constants.MINTER, game_);
        games[game_].enabled = false;
    }

    /**
     * Gettors
     */
    function getStageTimes() external view returns (uint256[] memory) {
        return stageTimes;
    }

    /**
     * Bear Pouch setters (helper functions)
     * Can check roles directly since this is an access control
     */

    function setJani(address jani_) external onlyRole(Constants.GAME_ADMIN) {
        _grantRole(Constants.JANI, jani_);
    }

    function setBeekeeper(address beeKeeper_) external onlyRole(Constants.GAME_ADMIN) {
        _grantRole(Constants.JANI, beeKeeper_);
    }

    function setStageTimes(uint24[] calldata _stageTimes) external onlyRole(Constants.GAME_ADMIN) {
        stageTimes = _stageTimes;
    }
}

abstract contract GameRegistryConsumer {
    GameRegistry public gameRegistry;

    error GameRegistry_NoPermissions(string role, address user);
    error GameRegistry_StageOutOfBounds(uint8 index);

    modifier onlyRole(bytes32 role_) {
        if (!gameRegistry.hasRole(role_, msg.sender)) {
            revert GameRegistry_NoPermissions(string(abi.encodePacked(role_)), msg.sender);
        }
        _;
    }

    constructor(address gameRegistry_) {
        gameRegistry = GameRegistry(gameRegistry_);
    }

    function _isEnabled(address game_) internal view returns (bool enabled) {
        enabled = gameRegistry.games(game_);
    }

    /// @dev the last stageTime is generalMint
    function _getStages() internal view returns (uint256[] memory) {
        return gameRegistry.getStageTimes();
    }

    /// @dev just a helper function. For access to all stages you should use _getStages()
    function _getStage(uint8 stageIndex) internal view returns (uint256) {
        uint256[] memory stageTimes = gameRegistry.getStageTimes();
        if (stageIndex >= stageTimes.length) revert GameRegistry_StageOutOfBounds(stageIndex);

        return stageTimes[stageIndex];
    }

    function _hasRole(bytes32 role_) internal view returns (bool) {
        return gameRegistry.hasRole(role_, msg.sender);
    }
}