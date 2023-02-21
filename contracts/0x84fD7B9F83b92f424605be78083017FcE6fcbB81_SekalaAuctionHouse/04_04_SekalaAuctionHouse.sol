// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;

    function transferFrom(address, address, uint) external;
}

contract SekalaAuctionHouse is Ownable, ReentrancyGuard {
    error AuctionNotInitialized();
    error AuctionNotLive();
    error AuctionLive();
    error ReservePriceNotMet();
    error WithdrawFailed();
    error NotEOA();
    error IncrementalPriceNotMet();
    error BuyPriceNotMet();
    error CanvasSold();

    event AuctionCreatedUpdated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 timeBuffer,
        uint256 reservePrice,
        uint256 minBidIncrementPercentage,
        uint256 buyAmount
    );
    event AuctionPriceUpdated(uint256 indexed auctionId, uint256 reservePrice);
    event Bid(uint256 indexed tokenId, address indexed sender, uint amount);
    event BidIncreased(
        uint256 indexed tokenId,
        address indexed sender,
        uint256 amount
    );
    event Buy(uint256 indexed tokenId, address indexed sender, uint256 amount);
    event AuctionExtended();
    event End(uint256 indexed tokenId, address indexed sender, uint256 amount);

    struct Auction {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 timeBuffer;
        uint256 reservePrice;
        uint256 minBidIncrementPercentage;
        address bidder;
        uint256 amount;
        uint256 buyAmount;
        bool isSold;
    }

    mapping(uint256 => Auction) public tokenIdToAuction;

    constructor() {}

    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert NotEOA();
        }
        _;
    }

    function createAuctions(Auction[] calldata auctions) external onlyOwner {
        for (uint256 i; i < auctions.length; ) {
            Auction storage auction = tokenIdToAuction[auctions[i].tokenId];

            auction.seller = msg.sender;
            auction.nftContract = auctions[i].nftContract;
            auction.tokenId = auctions[i].tokenId;
            auction.startTime = auctions[i].startTime;
            auction.endTime = auctions[i].endTime;
            auction.timeBuffer = auctions[i].timeBuffer;
            auction.reservePrice = auctions[i].reservePrice;
            auction.minBidIncrementPercentage = auctions[i]
                .minBidIncrementPercentage;
            auction.amount = auctions[i].amount;
            auction.buyAmount = auctions[i].buyAmount;

            emit AuctionCreatedUpdated({
                seller: msg.sender,
                nftContract: auctions[i].nftContract,
                tokenId: auctions[i].tokenId,
                startTime: auctions[i].startTime,
                endTime: auctions[i].endTime,
                timeBuffer: auctions[i].timeBuffer,
                reservePrice: auctions[i].reservePrice,
                minBidIncrementPercentage: auctions[i]
                    .minBidIncrementPercentage,
                buyAmount: auctions[i].buyAmount
            });

            unchecked {
                ++i;
            }
        }
    }

    function updateAuction(
        uint256 tokenId,
        address seller,
        address nftContract,
        uint256 startTime,
        uint256 endTime,
        uint256 timeBuffer,
        uint256 reservePrice,
        uint256 minBidIncrementPercentage,
        uint256 buyAmount
    ) external onlyOwner {
        Auction storage auction = tokenIdToAuction[tokenId];

        auction.seller = seller;
        auction.nftContract = nftContract;
        auction.startTime = startTime;
        auction.endTime = endTime;
        auction.timeBuffer = timeBuffer;
        auction.reservePrice = reservePrice;
        auction.minBidIncrementPercentage = minBidIncrementPercentage;
        auction.buyAmount = buyAmount;

        emit AuctionCreatedUpdated({
            seller: seller,
            nftContract: nftContract,
            tokenId: tokenId,
            startTime: startTime,
            endTime: endTime,
            timeBuffer: timeBuffer,
            reservePrice: reservePrice,
            minBidIncrementPercentage: minBidIncrementPercentage,
            buyAmount: buyAmount
        });
    }

    function bid(uint tokenId) external payable nonReentrant onlyEOA {
        Auction storage auction = tokenIdToAuction[tokenId];

        if (auction.isSold) {
            revert CanvasSold();
        }
        if (auction.startTime == 0 || auction.endTime == 0) {
            revert AuctionNotInitialized();
        }
        if (
            block.timestamp < auction.startTime ||
            block.timestamp > auction.endTime
        ) {
            revert AuctionNotLive();
        }

        if (auction.bidder == msg.sender) {
            // Case when the user already has an active bid
            if (
                msg.value <
                (auction.amount * auction.minBidIncrementPercentage) / 100 ||
                msg.value == 0
            ) {
                revert IncrementalPriceNotMet();
            }

            uint oldValue = auction.amount;
            unchecked {
                auction.amount = oldValue + uint(msg.value);
            }

            emit BidIncreased(tokenId, msg.sender, auction.amount);
        } else {
            if (msg.value < auction.reservePrice || msg.value == 0) {
                revert ReservePriceNotMet();
            }

            // check if there was a previous bid
            if (auction.bidder != address(0)) {
                if (
                    msg.value <
                    auction.amount +
                        (auction.amount * auction.minBidIncrementPercentage) /
                        100
                ) {
                    revert IncrementalPriceNotMet();
                }
            }

            // Refund latest bidder
            if (auction.bidder != address(0)) {
                _transferETH(auction.bidder, auction.amount);
            }

            auction.bidder = msg.sender;
            auction.amount = msg.value;

            emit Bid(tokenId, msg.sender, msg.value);
        }

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        if (auction.endTime - block.timestamp < auction.timeBuffer) {
            unchecked {
                auction.endTime = block.timestamp + auction.timeBuffer;
            }
            emit AuctionExtended();
        }
    }

    function buy(uint256 tokenId) external payable nonReentrant onlyEOA {
        Auction storage auction = tokenIdToAuction[tokenId];

        if (auction.isSold) {
            revert CanvasSold();
        }
        if (auction.startTime == 0 || auction.endTime == 0) {
            revert AuctionNotInitialized();
        }
        if (
            block.timestamp < auction.startTime ||
            block.timestamp > auction.endTime
        ) {
            revert AuctionNotLive();
        }

        if (auction.bidder == msg.sender) {
            // Case when the user already has an active bid
            if (
                msg.value < auction.buyAmount - auction.amount || msg.value == 0
            ) {
                revert BuyPriceNotMet();
            }
        } else {
            if (msg.value < auction.buyAmount || msg.value == 0) {
                revert BuyPriceNotMet();
            }

            // Refund latest bidder
            if (auction.bidder != address(0)) {
                _transferETH(auction.bidder, auction.amount);
            }
        }

        emit Buy(tokenId, msg.sender, auction.buyAmount);

        auction.isSold = true;

        IERC721(auction.nftContract).safeTransferFrom(
            auction.seller,
            msg.sender,
            auction.tokenId
        );

        emit End(tokenId, msg.sender, auction.buyAmount);
    }

    function end(uint256[] calldata _tokenIds) external nonReentrant onlyOwner {
        for (uint256 i; i < _tokenIds.length; ) {
            Auction storage auction = tokenIdToAuction[_tokenIds[i]];

            if (auction.isSold) {
                revert CanvasSold();
            }
            if (auction.startTime == 0 || auction.endTime == 0) {
                revert AuctionNotInitialized();
            }
            if (
                block.timestamp > auction.startTime &&
                block.timestamp < auction.endTime
            ) {
                revert AuctionLive();
            }

            auction.isSold = true;

            if (auction.bidder != address(0)) {
                IERC721(auction.nftContract).safeTransferFrom(
                    auction.seller,
                    auction.bidder,
                    auction.tokenId
                );
            }

            emit End(_tokenIds[i], auction.bidder, auction.amount);

            unchecked {
                ++i;
            }
        }
    }

    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30000}(new bytes(0));
        return success;
    }

    function withdraw() external onlyOwner {
        bool success = _transferETH(msg.sender, address(this).balance);
        if (!success) {
            revert WithdrawFailed();
        }
    }
}