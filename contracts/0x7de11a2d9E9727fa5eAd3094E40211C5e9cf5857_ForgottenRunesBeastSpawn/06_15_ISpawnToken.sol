// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BeastsToken

pragma solidity ^0.8.6;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface ISpawnToken is IERC721 {
    /// @notice Spawned event is emitted whenever a token is spawned
    event Spawned(
        uint256 spawnTokenId,
        uint256 beastTokenId,
        uint256 spawnIndex
    );

    function mint(
        address recipient,
        uint256 beastTokenId,
        uint256 spawnIndex
    ) external returns (uint256);
}