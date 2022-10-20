// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./SalePlatformStorage.sol";

abstract contract ContinuousDutchAuctionUpgradeable {
    function auctions(uint256 auctionId)
        public
        view
        returns (
            uint256 startingPrice,
            uint128 decreasingConstant,
            uint64 start,
            uint64 period,
            bool active
        )
    {
        Auction memory auction = SalePlatformStorage.layout().auctions[
            auctionId
        ];
        startingPrice = auction.startingPrice;
        decreasingConstant = auction.decreasingConstant;
        start = auction.start;
        period = auction.period;
        active = start > 0 && block.timestamp >= start;
    }

    function setAuction(
        uint256 auctionId,
        uint256 startingPrice,
        uint128 decreasingConstant,
        uint64 start,
        uint64 period
    ) public virtual {
        unchecked {
            require(
                startingPrice - decreasingConstant * period <= startingPrice,
                "setAuction: floor price underflow"
            );
        }
        SalePlatformStorage.layout().auctions[auctionId] = Auction(
            startingPrice,
            decreasingConstant,
            start,
            period
        );
    }

    function getPrice(uint256 auctionId)
        public
        view
        virtual
        returns (uint256 price)
    {
        Auction memory auction = SalePlatformStorage.layout().auctions[
            auctionId
        ];
        //only compute correct price if necessary
        if (block.timestamp < auction.start) price = auction.startingPrice;
        else if (block.timestamp >= auction.start + auction.period)
            price =
                auction.startingPrice -
                auction.period *
                auction.decreasingConstant;
        else
            price =
                auction.startingPrice -
                (auction.decreasingConstant *
                    (block.timestamp - auction.start));
    }

    function verifyBid(uint256 auctionId) internal returns (uint256) {
        Auction memory auction = SalePlatformStorage.layout().auctions[
            auctionId
        ];
        require(auction.start > 0, "AUCTION:NOT CREATED");
        require(
            block.timestamp >= auction.start,
            "PURCHASE:AUCTION NOT STARTED"
        );
        uint256 pricePaid = getPrice(auctionId);
        require(msg.value >= pricePaid, "PURCHASE:INCORRECT MSG.VALUE");
        if (msg.value - pricePaid > 0)
            AddressUpgradeable.sendValue(
                payable(msg.sender),
                msg.value - pricePaid
            ); //refund difference
        return pricePaid;
    }
}