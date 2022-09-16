//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzEvents {
    event Revealed(uint256 currentTokenId);
    event NameChanged(uint256 indexed id, string name);
    event LoreChanged(uint256 indexed id, string lore);
    event Equipped(uint256 indexed id, string typeOf, uint256 itemTokenId);
    event Unequipped(uint256 indexed id, string typeOf, uint256 itemTokenId);
    event Staked(uint256 indexed id);
    event UnStaked(uint256 indexed id, uint256 amount);
    event ClaimedTokens(uint256 indexed id, uint256 amount);
}