// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

    struct TokenInfo {
        uint tokenId;
        uint heroId;
        uint rarity;
    }

    struct MintInfo {
        uint tokenId;
        uint amount;
        address user;
        bool forWhitelist;
    }

    struct MergeInfo {
        uint tokenIdA;
        uint tokenIdB;
        address user;
        uint price;
        uint blockNumber;
    }