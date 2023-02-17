// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

enum CollectionType {
    OneOfOnes,
    Editions
}

enum DropType {
    FixedPrice,
    StandardAuction
}

// TODO: rearrange to minimize calldata bytes size
struct DropMgmtAuth {
    // slot 1
    uint256 id;
    // slot 2
    bytes32 r;
    // slot 3
    bytes32 s;
    // slot 4
    uint8 v; // TODO: move down to occupy 1 less slot
    // slot 5
    uint256 validFrom;
    // slot 6
    uint256 validPeriod;
    // slot 7
    DropType dropType; // TODO: move down to occupy 1 less slot
    // slot 8
    uint256 dropId;
    // slot 9
    address collection; // TODO: move down to occupy 1 less slot
    // slot 10
    bytes32 merkleRoot;
    // slot 11
    uint32 numItems;
    uint96 price;
    uint128 start;
    uint32 period;
    CollectionType collectionType;
    uint32 supply; // TODO: rename to editionsSupply
}

// TODO: rearrange to minimize calldata bytes size
struct DropCancellationAuth {
    // slot 1
    uint256 id;
    // slot 2
    bytes32 r;
    // slot 3
    bytes32 s;
    // slot 4
    uint8 v; // TODO: move down to occupy 1 less slot
    // slot 5
    uint256 validFrom;
    // slot 6
    uint256 validPeriod;
    // slot 7
    DropType dropType;
    uint256 dropId;
}

struct MintAuth {
    // slot 1
    uint256 id;
    // slot 2
    bytes32 r;
    // slot 3
    bytes32 s;
    // slot 4
    uint256 validFrom;
    // slot 5
    uint256 validPeriod;
    // slot 6
    uint256 dropId;
    // slot 7
    uint256 itemId;
    // slot 8
    bytes32[] proof;
    // slot 9
    uint8 v;
    DropType dropType;
    address to;
    uint32 quantity;
}