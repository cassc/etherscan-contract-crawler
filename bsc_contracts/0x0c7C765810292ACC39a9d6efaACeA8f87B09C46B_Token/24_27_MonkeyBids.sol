// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MonkeyBids is Ownable, ReentrancyGuard {
    enum AuctionStatus {
        Created,
        Bidding,
        Closed,
        Settled,
        Cancelled
    }

    struct Auction {
        address seller;
        AuctionStatus status;
        uint256 startBlock;
        uint256 endBlock;
        uint256 bidPrice;
        uint256 bidBlockIncrement;
        IERC20 purchaseToken;
        uint256 purchasePrice;
        uint256 purchasePriceIncrement;
        address lastBidder;
        uint256 bidCount;
        uint256 bidAmount;
    }

    IERC20 public immutable bidToken;
    mapping(string => Auction) public auctions;

    function concatString(string memory a, string memory b) external pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    constructor(address bidToken_) {
        require(bidToken_ != address(0x0));
        bidToken = IERC20(bidToken_);
    }

    function createAuction(
        string calldata auctionId,
        uint256 startBlock,
        uint256 endBlock,
        uint256 bidPrice,
        uint256 bidBlockIncrement,
        IERC20 purchaseToken,
        uint256 purchasePrice,
        uint256 purchasePriceIncrement,
        address seller
    ) external onlyOwner nonReentrant {
        require(seller != address(0x0));

        Auction storage auction = auctions[auctionId];
        require(auction.seller == address(0x0), "MonkeyBids: auction already exists.");

        auction.seller = seller;
        auction.status = AuctionStatus.Created;
        auction.startBlock = startBlock;
        auction.endBlock = endBlock;
        auction.bidPrice = bidPrice;
        auction.bidBlockIncrement = bidBlockIncrement;
        auction.purchaseToken = purchaseToken;
        auction.purchasePrice = purchasePrice;
        auction.purchasePriceIncrement = purchasePriceIncrement;
        auction.bidAmount = 0;
    }

    function cancelAuction(string calldata auctionId)
        external
        onlyOwner
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];
        require(block.number <= auction.endBlock, "MonkeyBids: cannot cancel after expiry.");
        auction.status = AuctionStatus.Cancelled;
    }

    function closeAuction(string calldata auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];
        bidToken.transferFrom(address(this), msg.sender, auction.bidAmount);
        auction.status = AuctionStatus.Closed;
    }

    function bid(string calldata auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];

        require(
            auction.status == AuctionStatus.Bidding ||
                auction.status == AuctionStatus.Created, "MonkeyBids: auction not open."
        );
        require(block.number >= auction.startBlock);
        require(block.number <= auction.endBlock, "MonkeyBids: auction expired.");
        require(auction.bidPrice <= bidToken.balanceOf(msg.sender));

        bidToken.transferFrom(msg.sender, address(this), auction.bidPrice);

        auction.status = AuctionStatus.Bidding;
        auction.lastBidder = msg.sender;
        auction.bidCount++;
        auction.purchasePrice += auction.purchasePriceIncrement;
        auction.bidAmount += auction.bidPrice;
    }

    function settle(string calldata auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.Bidding);
        require(block.number > auction.endBlock, "MonkeyBids: cannot settle before expiry.");
        require(auction.lastBidder != address(0x0));
        require(msg.sender == auction.lastBidder, "MonkeyBids: only last bidder can settle.");

        require(
            auction.purchasePrice <=
                auction.purchaseToken.balanceOf(auction.seller)
        );
        auction.purchaseToken.transferFrom(
            msg.sender,
            auction.seller,
            auction.purchasePrice
        );
        auction.status = AuctionStatus.Settled;
    }

    function withdraw(string calldata auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.Settled);
        require(msg.sender == auction.seller);
        bidToken.transfer(msg.sender, auction.bidAmount);
        auction.status = AuctionStatus.Closed;
    }
}