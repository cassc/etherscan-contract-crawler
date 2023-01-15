// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct NFTCollection {
    uint32 chainId;
    address tokenAddress;
}

struct NFT {
    uint256 tokenId;
    NFTCollection collection;
}