// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct TokenOwner {
    bool transferred;
    uint88 transferCount;
    address ownerAddress;
}

struct SignatureECDSA {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct Redemption721 {
    uint256 nonce;
    uint256 expiration;
    address destination;
    address tokenAddress;
    uint256 tokenId;
}

struct RedemptionBatch721 {
    uint256 nonce;
    uint256 expiration;
    address destination;
    address[] tokenAddresses;
    uint256[] tokenIds;
}

struct Redemption1155 {
    uint256 nonce;
    uint256 expiration;
    address destination;
    address tokenAddress;
    uint256[] tokenIds;
    uint256[] amounts;
}

struct TokenTypeSupply {
    bool registered;
    uint120 amountCreated;
    uint120 remainingMintableSupply;
}

struct AuthorizedMint1155 {
    uint256 nonce;
    uint256 expiration;
    address destination;
    uint256 id;
    uint120 amount;
}