// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../interface/IFragmentToken.sol";

struct SafeBox {
    /// Either matching a key OR Constants.SAFEBOX_KEY_NOTATION meaning temporarily
    /// held by a bidder in auction.
    uint64 keyId;
    /// The timestamp that the safe box expires.
    uint32 expiryTs;
    /// The owner of the safebox. It maybe outdated due to expiry
    address owner;
}

struct PrivateOffer {
    /// private offer end time
    uint96 endTime;
    /// which token used to accpet the offer
    address token;
    /// price of the offer
    uint96 price;
    address owner;
    /// who should receive the offer
    address buyer;
    uint64 activityId;
}

struct AuctionInfo {
    /// The end time for the auction.
    uint96 endTime;
    /// Bid token address.
    address bidTokenAddress;
    /// Minimum Bid.
    uint96 minimumBid;
    /// The person who trigger the auction at the beginning.
    address triggerAddress;
    uint96 lastBidAmount;
    address lastBidder;
    /// Whether the auction is triggered by the NFT owner itself？
    bool isSelfTriggered;
    uint64 activityId;
    uint32 feeRateBips;
}

struct TicketRecord {
    /// who buy the tickets
    address buyer;
    /// Start index of tickets
    /// [startIdx, endIdx)
    uint48 startIdx;
    /// End index of tickets
    uint48 endIdx;
}

struct RaffleInfo {
    /// raffle end time
    uint48 endTime;
    /// max tickets amount the raffle can sell
    uint48 maxTickets;
    /// which token used to buy the raffle tickets
    address token;
    /// price per ticket
    uint96 ticketPrice;
    /// total funds collected by selling tickets
    uint96 collectedFund;
    uint64 activityId;
    address owner;
    /// total sold tickets amount
    uint48 ticketSold;
    uint32 feeRateBips;
    /// whether the raffle is being settling
    bool isSettling;
    /// tickets sold records
    TicketRecord[] tickets;
}

struct CollectionState {
    /// The address of the Floor Token cooresponding to the NFTs.
    IFragmentToken floorToken;
    /// Records the active safe box in each time bucket.
    mapping(uint256 => uint256) countingBuckets;
    /// Stores all of the NFTs that has been fragmented but *without* locked up limit.
    uint256[] freeTokenIds;
    /// Huge map for all the `SafeBox`es in one collection.
    mapping(uint256 => SafeBox) safeBoxes;
    /// Stores all the ongoing auctions: nftId => `AuctionInfo`.
    mapping(uint256 => AuctionInfo) activeAuctions;
    /// Stores all the ongoing raffles: nftId => `RaffleInfo`.
    mapping(uint256 => RaffleInfo) activeRaffles;
    /// Stores all the ongoing private offers: nftId => `PrivateOffer`.
    mapping(uint256 => PrivateOffer) activePrivateOffers;
    /// The last bucket time the `countingBuckets` is updated.
    uint64 lastUpdatedBucket;
    /// Next Key Id. This should start from 1, we treat key id `SafeboxLib.SAFEBOX_KEY_NOTATION` as temporarily
    /// being used for activities(auction/raffle).
    uint64 nextKeyId;
    /// Active Safe Box Count.
    uint64 activeSafeBoxCnt;
    /// The number of infinite lock count.
    uint64 infiniteCnt;
    /// Next Activity Id. This should start from 1
    uint64 nextActivityId;
}

struct UserFloorAccount {
    /// @notice it should be maximum of the `totalLockingCredit` across all collections
    uint96 minMaintCredit;
    /// @notice used to iterate collection accounts
    /// packed with `minMaintCredit` to reduce storage slot access
    address firstCollection;
    /// @notice user vip level related info
    /// 0 - 239 bits: store SafeBoxKey Count per vip level, per level using 24 bits
    /// 240 - 247 bits: store minMaintVipLevel
    /// 248 - 255 bits: remaining
    uint256 vipInfo;
    /// @notice Locked Credit amount which cannot be withdrawn and will be released as time goes.
    uint256 lockedCredit;
    mapping(address => CollectionAccount) accounts;
    mapping(address => uint256) tokenAmounts;
}

struct SafeBoxKey {
    /// locked credit amount of this safebox
    uint96 lockingCredit;
    /// corresponding key id of the safebox
    uint64 keyId;
    /// which vip level the safebox locked
    uint8 vipLevel;
}

struct CollectionAccount {
    mapping(uint256 => SafeBoxKey) keys;
    /// total locking credit of all `keys` in this collection
    uint96 totalLockingCredit;
    /// track next collection as linked list
    address next;
}

/// Internal Structure
struct LockParam {
    address proxyCollection;
    address collection;
    uint256[] nftIds;
    uint256 expiryTs;
    uint256 vipLevel;
    uint256 maxCreditCost;
    address creditToken;
}