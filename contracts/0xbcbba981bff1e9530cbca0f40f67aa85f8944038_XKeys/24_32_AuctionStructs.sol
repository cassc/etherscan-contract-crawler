// SPDX-License-Identifier: UNLICENCED

pragma solidity 0.8.20;

import "./AuctionEnums.sol";

// uint120 is 15 bytes, therefore the whole struct is 31 bytes
// this improves gas perfomance of claim and bid by quite a large margin
struct Bidder {
    // the sum of the user's bids
    uint120 totalBid;
    // total funds refunded to the user
    uint120 refundedFunds;
    // whether or not the user has claimed already
    bool claimed; // 1 byte
}

// @dev the uint limits are intentional
struct Auction {
    // the auction id
    uint8 id; // 1 byte
    // the auction stage
    AuctionStage stage; // 1 byte
    // the maximum number of pods that can be won by a single wallet
    uint8 maxWinPerWallet; // 1 byte
    //
    // the maximum number of pods that can be minted in this auction
    uint16 supply; // 2 bytes
    //
    // the number of minted NFTs for this auction
    uint16 remainingSupply; // 2 bytes
    //
    // minimum bid
    uint64 minimumBid; // 8 bytes
    // the price as computed by the binary search algorithm
    // it get set after the bidding is closed
    uint64 price; // 8 bytes
}