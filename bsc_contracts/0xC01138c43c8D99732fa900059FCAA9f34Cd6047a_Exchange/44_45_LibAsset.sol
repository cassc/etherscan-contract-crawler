// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LibAsset{
    enum AssetType {ETH, ERC20, ERC1155, ERC721, ERC721Deprecated}

    struct Asset {
        address token;
        uint256 tokenId;
        uint256 tokenAmount;
        AssetType assetType;
    }
}