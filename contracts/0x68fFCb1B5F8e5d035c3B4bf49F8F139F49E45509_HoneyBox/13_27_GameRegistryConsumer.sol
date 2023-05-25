// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {GameRegistry} from "./GameRegistry.sol";

/// @title GameRegistryConsumer
/// @notice all contracts within the THJ universe should inherit from this contract.
abstract contract GameRegistryConsumer {
    GameRegistry public immutable gameRegistry;

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