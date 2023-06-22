// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NPC

pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface INPC is IERC721 {
    event NPCCreated(uint256 indexed tokenId);

    event FounderNPCCreated(uint256 indexed tokenId);

    event NPCBurned(uint256 indexed tokenId);

    event NPCWalletUpdated(address NPCWallet);

    event NPCTokenURISet(uint256 indexed tokenId, string tokenURI);

    event MinterUpdated(address minter);

    event SetterUpdated(address setter);

    event MinterLocked();

    event SetterLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function setMinter(address minter) external;

    function setSetter(address setter) external;

    function lockMinter() external;

    function lockSetter() external;

    function setNPCWallet(address _NPCWallet) external; 
}