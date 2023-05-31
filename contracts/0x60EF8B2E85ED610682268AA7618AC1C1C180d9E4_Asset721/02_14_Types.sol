// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error OnlyAdminCanPerformThisAction();
error OnlyAuthorizedCanPerformThisAction();
error AlreadyInitialized();
error ExpiredSignature();
error InvalidSignature();

library Types {
    enum AssetKind {
        NONE,
        ERC721,
        ERC1155
    }

    struct Sign {
        address signer;
        bytes signature;
        uint256 timestamp;
    }

    struct Asset {
        AssetKind kind;
        uint256 batchId;
        uint256 tierId;
        uint256 amount;
        uint256 mintAmount;
        string uri;
        address swapToken;
        address to;
        address target;
        bytes32[] proof;
    }
}