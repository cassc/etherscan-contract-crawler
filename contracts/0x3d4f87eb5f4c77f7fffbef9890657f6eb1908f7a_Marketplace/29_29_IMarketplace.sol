// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IMarketplace {
    enum AUCTION_STATUS {NO_STATUS, IN_PENDING, IN_PROGRESS, SUCCESSFUL, CANCELLED, FAILED}
    enum FIXED_PRICE_STATUS {NO_STATUS, IN_PROGRESS, SUCCESSFUL, CANCELLED}

    struct Auction {
        address seller;
        uint256 tokenId;
        uint256 minPriceSell;
        uint256 minBidStep;
        uint256 startTime;
        uint256 endTime;
        address lastBidder;
        uint256 lastBidTime;
        uint256 currentBid;
        address erc1155NFT;
        address erc20;
        AUCTION_STATUS status;
        uint256 blockNumber;
    }

    struct FixedPriceSale {
        address seller;
        address erc1155NFT;
        uint256 tokenId;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        address erc20;
        FIXED_PRICE_STATUS status;
    }

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 minPrice, uint256 minBidStep, uint256 startTime, uint256 auctionEndTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 bid);
    event LastBlockNumberBid (uint256 indexed blockNumber);
    event AuctionEnded(uint256 indexed auctionId, address indexed seller, address indexed nftAddress, uint256 tokenId, address winner, uint256 price);
    event AuctionCancelled(uint256 indexed auctionId, address indexed seller, address indexed nftAddress, uint256 tokenId);
    event FixedPriceSaleCreated(uint256 indexed fixedPriceSaleId, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 startTime, uint256 fixedPriceSaleEndTime, uint256 price);
    event FixedPriceSaleEnded(uint256 indexed fixedPriceSaleId, address indexed seller, address indexed nftAddress, uint256 tokenId, address buyer, uint256 price);
    event FixedPriceSaleCancelled(uint256 indexed fixedPriceSaleId, address indexed seller, address indexed nftAddress, uint256 tokenId);

    function createAuction(address erc20Address, address erc1155NFT, uint256 tokenId, uint256 minPriceSell, uint256 minBidStep, uint256 startTime, uint256 auctionDuration) external;
    function placeBid(uint256 _auctionId, uint256 amount) external;
    function cancelAuction(uint256 _auctionId) external;
    function createFixedPriceSale(address erc20Address, address erc1155NFT, uint256 tokenId, uint256 startTime, uint256 fixedPriceSaleDuration, uint256 price) external;
    function buyFixedPriceSale(uint256 _fixedPriceSaleId) external;
}