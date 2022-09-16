// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface NiftySouqIAuction {
    struct Bid {
        address bidder;
        uint256 price;
        uint256 bidAt;
        bool canceled;
    }

    struct Auction {
        uint256 tokenId;
        address tokenContract;
        uint256 startTime;
        uint256 endTime;
        address seller;
        uint256 startBidPrice;
        uint256 reservePrice;
        uint256 highestBidIdx;
        uint256 selectedBid;
        Bid[] bids;
    }

    struct CreateAuction {
        uint256 offerId;
        uint256 tokenId;
        address tokenContract;
        uint256 startTime;
        uint256 duration;
        address seller;
        uint256 startBidPrice;
        uint256 reservePrice;
    }

    function createAuction(CreateAuction calldata createAuctionData_) external;

    function cancelAuction(uint256 offerId)
        external
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        );

    function placeBid(
        uint256 offerId,
        address bidder,
        uint256 bidPrice
    ) external returns (uint256 bidIdx_);

    function placeHigherBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx,
        uint256 bidPrice
    ) external returns (uint256 currentBidPrice_);

    function cancelBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx
    )
        external
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        );

    function endAuction(
        uint256 offerId_,
        address creator,
        uint256 bidIdx
    )
        external
        returns (
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        );

    function endAuctionWithHighestBid(uint256 offerId_, address creator_)
        external
        returns (
            uint256 bidIdx_,
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        );

    function getAuctionDetails(uint256 offerId_)
        external
        view
        returns (Auction memory auction_);
}