// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "../libs/AuthStructs.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./IDrop.sol";

struct StandardAuctionDrop {
    // first slot
    address collection;
    uint96 startingPrice;
    // second slot
    uint128 start;
    uint32 auctionPeriod;
    uint32 numMinted;
    uint32 numItems;
    bool cancelled;
    uint8 minBidIncrementPercent; // 0-100
    // third slot
    bytes32 merkleRoot;
}

struct StandardAuctionItemBid {
    // first slot
    uint96 highestBid;
    address highestBidder;
    // second slot
    bool minted;
    // `refunded` could be redundant wrt. drop.cancelled, but it's an extra check + allows to query on-chain if a bid has been refunded
    bool refunded;
}

struct BidAuth {
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
    address bidder;
    bytes32[] proof;
}

interface IStandardAuctionSale is IDrop {
    function drop(uint256 dropId)
        external
        view
        returns (
            address,
            uint96,
            uint128,
            uint32,
            bool,
            uint32,
            uint32,
            uint8
        );

    function getBid(uint256 dropId, uint256 itemId)
        external
        view
        returns (
            address,
            uint96,
            bool,
            bool
        );

    function publishDrop(
        uint256 voucherId,
        uint256 dropId,
        address collection,
        bytes32 merkleProof,
        uint96 startingPrice,
        uint128 start,
        uint32 auctionPeriod,
        uint32 numItems
    ) external;

    function rePublishDrop(
        uint256 voucherId,
        uint256 dropId,
        bytes32 merkleProof,
        uint96 startingPrice,
        uint128 start,
        uint32 auctionPeriod,
        uint32 numItems
    ) external;

    function cancelDrop(uint256 voucherId, uint256 dropId) external;

    function authorizedBid(BidAuth calldata bidAuth) external payable;

    function highestBid(uint256 dropId, uint256 itemId)
        external
        view
        returns (uint96);

    function highestBidder(uint256 dropId, uint256 itemId)
        external
        view
        returns (address);

    function minimumBid(uint256 dropId, uint256 itemId)
        external
        view
        returns (uint96);

    function authorizedMint(
        MintAuth calldata mintAuth,
        string calldata uri,
        bytes calldata data
    ) external payable;
}