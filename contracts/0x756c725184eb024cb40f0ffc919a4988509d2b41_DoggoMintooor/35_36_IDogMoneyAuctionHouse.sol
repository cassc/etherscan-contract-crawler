// SPDX-License-Identifier: CC-BY-NC-ND-1.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDogMoneyAuctionHouse {
    struct Auction {
        // The id of this auction.
        uint256 id;
        // The package containing which tokens are to be auctioned.
        AuctionPack auctionPack;
        // The current highest bid amount.
        uint256 amount;
        // The time that the auction started.
        uint256 startTime;
        // The time that the auction is scheduled to end.
        uint256 endTime;
        // The address of the current highest bid.
        address payable bidder;
        // Whether or not the auction has been settled.
        bool settled;
        // If there isn't balance for an auction, or it was made
        // erroneously, then the auction operator can cancel it.
        bool cancelled;
        // Used to recycle through old auctions.
        uint256 lastAttempt;
    }

    struct AuctionPack {
        bool isInitialized;
        string metadataURI;
        uint256 reservePrice;
        address[] erc20Addresses;
        uint256[] erc20Amounts;
        address[] erc721Addresses;
        uint256[] erc721TokenIds;
        address[] erc1155Addresses;
        uint256[] erc1155Amounts;
        uint256[] erc1155TokenIds;
        // Duration in seconds.
        uint256 duration;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed auctionId,
        address sender,
        uint256 value,
        bool extended
    );

    event AuctionExtended(uint256 indexed auctionId, uint256 endTime);

    event AuctionSettled(
        uint256 indexed auctionId,
        address winner,
        uint256 amount
    );

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    function settleAuction() external;

    function settleAuction(bool forceSettle) external;

    function createAuction() external;

    function createAuction(AuctionPack memory auctionPack) external;

    function setNextAuctions(AuctionPack[] memory auctionPack) external;

    function createBid(
        uint256 auctionId,
        IERC20 token,
        bytes memory swapPath,
        uint256 amountInReserveCurrency,
        uint256 amountInMaximum
    ) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(
        uint8 minBidIncrementPercentage
    ) external;

    function cancelAuction(uint256 auctionId) external;
}