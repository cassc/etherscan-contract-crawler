// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

enum CoinSide {
    HEADS, TAILS
}

enum CoinType {
    Unrevealed, Crown, Banana, Diamond, Ape
}

struct Token {
    uint16 tokenId; CoinType coinType; address owner;
}

struct AccountTokenData {
    uint16 balance; Token[] tokens;
}

bytes32 constant ADMIN = keccak256("ADMIN");
bytes32 constant OPERATOR = keccak256("OPERATOR");