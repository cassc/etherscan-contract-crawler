// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IVanillaV1MigrationTarget02 {
    /// @notice Called by IVanillaV1Router02#migratePosition.
    /// @dev Router transfers the tokens before calling this function, so that balance can be verified.
    function migrateState(address owner, address token, uint256 ethSum, uint256 tokenSum, uint256 weightedBlockSum, uint256 latestBlock) external;
}