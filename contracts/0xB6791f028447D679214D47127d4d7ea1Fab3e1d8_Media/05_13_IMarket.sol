//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IMarket {
    struct Sale {
        uint256 itemId;
        uint256 tokenId;
        uint256 price;
        uint256 quantity;
        uint256 time;
        address nftContract;
        address erc20Token;
        address buyer;
        address seller;
        bool sold;
    }

    struct Auction {
        uint256 itemId;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 basePrice;
        uint256 quantity;
        uint256 time;
        Bid[] bids;
        address seller;
        address nftContract;
        address erc20Token;
        bool sold;
        Bid highestBid;
    }

    struct Bid {
        address bidder;
        uint256 bid;
    }

    event Mint(address from, address to, uint256 indexed tokenId);
    event PlaceBid(
        address nftAddress,
        address bidder,
        uint256 price,
        uint256 tokenId
    );
    event MarketItemCreated(
        address indexed nftAddress,
        address indexed seller,
        uint256 price,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event Buy(
        address indexed seller,
        address bidder,
        uint256 indexed price,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 quantity,
        uint256 startTime,
        uint256 endTime
    );
    event CancelBid(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed bidder
    );

    function sellitem(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external;

    function buyItem(
        address nftAddress,
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 quantity
    ) external payable;

    function createAuction(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 basePrice,
        uint256 endTime
    ) external;

    function placeBid(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId,
        uint256 price
    ) external payable;

    function approveBid(
        address nftAddress,
        address seller,
        uint256 tokenId,
        address bidder
    ) external;

    function claimNft(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId
    ) external;

    function cancelBid(
        address nftAddress,
        address _bidder,
        address seller,
        uint256 tokenId
    ) external;

    function cancelSell(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external;

    function cancelAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external;

    function revokeAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external;
}