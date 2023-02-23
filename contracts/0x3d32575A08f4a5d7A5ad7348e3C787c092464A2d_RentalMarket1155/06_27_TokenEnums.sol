// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

enum TokenType {
    ERC721,
    ERC721_subNFT, //Reserved Field
    ERC721_vNFT, //Reserved Field
    ERC1155,
    ERC4907,
    ERC5006,
    ERC20,
    NATIVE
}