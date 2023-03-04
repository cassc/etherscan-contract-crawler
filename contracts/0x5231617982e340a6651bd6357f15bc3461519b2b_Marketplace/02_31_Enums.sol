// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

enum OrderType {
    SWAP,
    SALE,
    OFFER
}

enum AssetType {
    Native,
    ERC20,
    ERC721,
    ERC1155
}