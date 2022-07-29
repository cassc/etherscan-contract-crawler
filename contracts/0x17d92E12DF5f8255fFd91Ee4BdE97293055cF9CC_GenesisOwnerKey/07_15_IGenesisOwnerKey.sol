//SPDX-License-Identifier: Unlicense
// Creator: Dai
pragma solidity ^0.8.4;

interface IGenesisOwnerKey {
    //Interface
    event Mint(address indexed operator, address indexed to, uint256 quantity);
    event Burn(address indexed operator, uint256 tokenID);
    event UpdateMetadataImage(string);
    event UpdateMetadataExternalUrl(string);
    event UpdateMetadataAnimationUrl(string);
    event SetupPool(address indexed operator, address pool);
    event Locked(address indexed operator, bool locked);
    event TradingAllowed(address indexed operator, bool allowed);
    event MintToPool(address indexed operator, uint256 quantity);
}