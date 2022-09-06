// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum ItemType {
    ERC20,
    ERC721
}

struct Item {
    address token;
    ItemType itemType;
    uint256 value; // amount for erc20, tokenId for erc721
}

struct Offer {
    Item[] toSend;
    Item[] toReceive;
    address from;
    address to;
    uint256 deadline;
}

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}