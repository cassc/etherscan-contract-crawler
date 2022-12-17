// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum OfferItemType {
    // 0: native token
    NATIVE,

    // 1: ERC-20 token
    ERC20,

    // 2: ERC-721 token
    ERC721,

    // 3: ERC-1155 token
    ERC1155
}