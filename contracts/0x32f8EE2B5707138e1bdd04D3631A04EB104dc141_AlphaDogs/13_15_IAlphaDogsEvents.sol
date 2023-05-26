// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaDogsEvents {
    event NameChanged(uint256 indexed id, string name);
    event LoreChanged(uint256 indexed id, string lore);
    event Breeded(uint256 indexed child, uint256 mom, uint256 dad);
    event Staked(uint256 indexed id);
    event Unstaked(uint256 indexed id, uint256 amount);
    event ClaimedTokens(uint256 indexed id, uint256 amount);
}