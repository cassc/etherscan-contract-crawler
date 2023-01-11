// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

enum DropType {
    FixedPrice,
    StandardAuction
}

// TODO: rearrange to minimize calldata bytes size
struct DropMgmtAuth {
    // basic voucher
    uint256 id;
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint256 validFrom;
    uint256 validPeriod;
    // drop details
    DropType dropType;
    uint256 dropId;
    address collection;
    bytes32 merkleRoot;
    uint32 maxSupply;
    uint96 price;
    uint128 start;
    // only needed for auctions
    uint32 period;
}

struct DropCancellationAuth {
    // basic voucher
    uint256 id;
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint256 validFrom;
    uint256 validPeriod;
    // drop details
    DropType dropType;
    uint256 dropId;
}

struct MintAuth {
    // basic voucher
    uint256 id;
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint256 validFrom;
    uint256 validPeriod;
    // drop mintDetails
    DropType dropType;
    uint256 dropId;
    uint256 itemId;
    address to;
    bytes32[] proof;
}