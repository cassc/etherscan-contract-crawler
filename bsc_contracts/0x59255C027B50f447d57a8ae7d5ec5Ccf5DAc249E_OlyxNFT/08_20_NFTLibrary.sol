// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library NFTLibrary{
    struct NFT {
        string name; 
        string category;
        uint8 level; 
        uint256 tokenId;
        bool stakeFreeze;
    }
}