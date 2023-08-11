// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRoyaltyCollector {
    struct NFTItem {
        address collection;
        uint256 tokenId;
    }

    function collectTokenRoyalties(NFTItem[] calldata nftItems) external;
}