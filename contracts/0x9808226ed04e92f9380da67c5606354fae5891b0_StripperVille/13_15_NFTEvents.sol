// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract NFTEvents {
    event NewTotalSupply(address indexed caller, uint newSupply);
    event NewStripperPrice(address indexed caller, uint newPrice);
    event NewMaxMint(address indexed caller, uint newMaxMint);
    event MintStripper(address indexed buyer, uint qty);
    event MintClub(address indexed caller, string clubName);
    event CloseClub(address indexed caller, uint tokenId);
    event ReopenClub(address indexed caller, uint tokenId);
    event NewAssetName(address indexed caller, uint indexed tokenId, string newName);
    event Giveaway(address indexed from, address indexed to, uint qty);
}