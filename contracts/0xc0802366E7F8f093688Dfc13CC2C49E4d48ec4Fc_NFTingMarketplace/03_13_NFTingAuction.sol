// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./utilities/NFTingBase.sol";

contract NFTingAuction is Ownable, NFTingBase {
    using Counters for Counters.Counter;

    struct Auction {
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
        address creator;
        uint256 startedAt;
        uint256 endAt;
        uint256 maxBidAmount;
        address winner;
        mapping(address => uint256) biddersToAmount;
        address[] bidders;
    }

    Counters.Counter private currentAuctionId;
    mapping(uint256 => Auction) internal auctions;

    event AuctionCreated(
        uint256 _auctionId,
        address indexed _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address indexed _creator,
        uint256 _startedAt,
        uint256 _endAt
    );
    event BidCreated(uint256 _auctionId, address _bidder, uint256 _amount);
    event BidUpdated(uint256 _auctionId, address _bidder, uint256 _amount);
    event AuctionFinished(uint256 _auctionId);

    modifier isValidAuction(uint256 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        if (auction.creator == address(0)) {
            revert NotExistingAuction(_auctionId);
        } else if (auction.endAt < block.timestamp) {
            revert ExpiredAuction(_auctionId);
        }

        _;
    }

    modifier isExistingBidder(uint256 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        if (auction.biddersToAmount[_msgSender()] == 0) {
            revert NotExistingBidder(_msgSender());
        }

        _;
    }

    modifier isExpiredAuction(uint256 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        if (auction.startedAt == 0) {
            revert NotExistingAuction(_auctionId);
        } else if (auction.endAt >= block.timestamp) {
            revert ValidAuction(_auctionId);
        }

        _;
    }

    modifier isBiddablePrice(uint256 _auctionId, uint256 _price) {
        Auction storage auction = auctions[_auctionId];
        if (
            auction.maxBidAmount >=
            _price + auction.biddersToAmount[_msgSender()]
        ) {
            revert NotEnoughPriceToBid();
        }

        _;
    }

    modifier isAuctionCreatorOrOwner(uint256 _auctionId) {
        if (
            auctions[_auctionId].creator != _msgSender() ||
            owner() != _msgSender()
        ) {
            revert NotAuctionCreatorOrOwner();
        }
        _;
    }

    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _durationInMinutes,
        uint256 _startingBid
    )
        external
        isValidAddress(_nftAddress)
        isTokenOwnerOrApproved(_nftAddress, _tokenId, _amount, _msgSender())
        isApprovedMarketplace(_nftAddress, _tokenId, _msgSender())
    {
        if (
            _amount == 0 ||
            (_amount > 1 &&
                _supportsInterface(_nftAddress, INTERFACE_ID_ERC721))
        ) {
            revert InvalidAmountOfTokens(_amount);
        }

        currentAuctionId.increment();
        uint256 auctionId = currentAuctionId.current();

        Auction storage newAuction = auctions[auctionId];
        newAuction.nftAddress = _nftAddress;
        newAuction.tokenId = _tokenId;
        newAuction.creator = _msgSender();
        newAuction.startedAt = block.timestamp;
        newAuction.endAt =
            newAuction.startedAt +
            _durationInMinutes *
            60 seconds;
        newAuction.maxBidAmount = _startingBid;
        newAuction.amount = _amount;

        _transfer721And1155(
            _msgSender(),
            address(this),
            newAuction.nftAddress,
            newAuction.tokenId,
            newAuction.amount
        );

        emit AuctionCreated(
            auctionId,
            newAuction.nftAddress,
            newAuction.tokenId,
            newAuction.amount,
            _msgSender(),
            newAuction.startedAt,
            newAuction.endAt
        );
    }

    function createBid(uint256 _auctionId, uint256 _price)
        external
        payable
        isValidAuction(_auctionId)
        isBiddablePrice(_auctionId, _price)
    {
        Auction storage auction = auctions[_auctionId];
        auction.biddersToAmount[_msgSender()] = _price;
        auction.winner = _msgSender();
        auction.maxBidAmount = _price;
        auction.bidders.push(_msgSender());

        emit BidCreated(_auctionId, _msgSender(), _price);
    }

    function increaseBidPrice(uint256 _auctionId, uint256 _additionalPrice)
        external
        payable
        isValidAuction(_auctionId)
        isExistingBidder(_auctionId)
        isBiddablePrice(_auctionId, _additionalPrice)
    {
        Auction storage auction = auctions[_auctionId];
        uint256 newAmount = auction.biddersToAmount[_msgSender()] +
            _additionalPrice;
        auction.biddersToAmount[_msgSender()] = newAmount;
        auction.winner = _msgSender();
        auction.maxBidAmount = newAmount;

        emit BidUpdated(_auctionId, _msgSender(), newAmount);
    }

    // Need to consider ERC1155, several tokenId
    function finishAuction(uint256 _auctionId)
        external
        isExpiredAuction(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];
        for (uint256 i; i < auction.bidders.length; i++) {
            address bidder = auction.bidders[i];
            if (bidder != auction.winner) {
                if (!payable(bidder).send(auction.biddersToAmount[bidder])) {
                    revert TransactionError();
                }
            } else {
                _transfer721And1155(
                    address(this),
                    auction.winner,
                    auction.nftAddress,
                    auction.tokenId,
                    auction.amount
                );
            }
        }

        delete auctions[_auctionId];

        emit AuctionFinished(_auctionId);
    }

    function getAuctionDetailsById(uint256 _auctionId)
        external
        view
        isValidAuction(_auctionId)
        returns (
            address,
            uint256,
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            address,
            address[] memory,
            uint256[] memory
        )
    {
        Auction storage curAuction = auctions[_auctionId];

        uint256[] memory amounts = new uint256[](
            curAuction.bidders.length
        );

        for (uint256 i; i < curAuction.bidders.length; i++) {
            amounts[i] = curAuction.biddersToAmount[
                curAuction.bidders[i]
            ];
        }
        return (
            curAuction.nftAddress,
            curAuction.tokenId,
            curAuction.amount,
            curAuction.creator,
            curAuction.startedAt,
            curAuction.endAt,
            curAuction.maxBidAmount,
            curAuction.winner,
            curAuction.bidders,
            amounts
        );
    }
}