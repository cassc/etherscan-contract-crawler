//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Bids {
    struct Item {
        uint256 amount;
        address bidder;
        address currency;
        uint256 timestamp;
    }

    struct Set {
        mapping(uint256 => Item) lotTopBid;
        mapping(address => uint256) lastBiddedLotOfBidder;
    }

    function add(
        Set storage set,
        uint256 lotKey,
        address bidder,
        uint256 amount,
        address currency
    ) internal {
        set.lotTopBid[lotKey] = Item({ amount: amount, bidder: bidder, currency: currency, timestamp: block.timestamp });
        set.lastBiddedLotOfBidder[bidder] = lotKey;
    }

    function getTopBidByLot(Set storage set, uint256 lotKey) internal view returns (Item memory) {
        return set.lotTopBid[lotKey];
    }

    function isTopBidder(Set storage set, address bidder) internal view returns (bool) {
        Item memory bid = getTopBidByLot(set, set.lastBiddedLotOfBidder[bidder]);

        return bidder == bid.bidder;
    }

    function getLastBiddedLotOfBidder(Set storage set, address bidder) internal view returns (uint256) {
        return set.lastBiddedLotOfBidder[bidder];
    }
}