// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./NFTingBase.sol";

contract NFTingAuction is NFTingBase {
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
        mapping(address => bool) biddersToClaimed;
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
    event AuctionCanceled(
        uint256 _auctionId,
        address indexed _nftAddress,
        uint256 _tokenId,
        address indexed _creator,
        uint256 _endAt
    );
    event BidCreated(uint256 _auctionId, address _bidder, uint256 _amount);
    event BidUpdated(uint256 _auctionId, address _bidder, uint256 _amount);

    modifier isRunningAuction(uint256 _auctionId) {
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
            revert RunningAuction(_auctionId);
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

    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _durationInMinutes,
        uint256 _startingBid
    )
        external
        onlyNFT(_nftAddress)
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
        newAuction.endAt = block.timestamp + _durationInMinutes * 60 seconds;
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

    function cancelAuction(uint256 _auctionId)
        external
        nonReentrant
        isRunningAuction(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];
        if (_msgSender() != auction.creator) revert NotAuctionCreatorOrOwner();
        auction.endAt = block.timestamp;
        auction.winner = address(0);

        _transfer721And1155(
            address(this),
            _msgSender(),
            auction.nftAddress,
            auction.tokenId,
            auction.amount
        );

        emit AuctionCanceled(
            _auctionId,
            auction.nftAddress,
            auction.tokenId,
            auction.creator,
            block.timestamp
        );
    }

    function createBid(uint256 _auctionId)
        external
        payable
        isRunningAuction(_auctionId)
        isBiddablePrice(_auctionId, msg.value)
    {
        Auction storage auction = auctions[_auctionId];
        if (_msgSender() == auction.creator) revert SelfBid();
        auction.biddersToAmount[_msgSender()] = msg.value;
        auction.winner = _msgSender();
        auction.maxBidAmount = msg.value;
        auction.bidders.push(_msgSender());

        emit BidCreated(_auctionId, _msgSender(), msg.value);
    }

    function increaseBidPrice(uint256 _auctionId)
        external
        payable
        isRunningAuction(_auctionId)
        isExistingBidder(_auctionId)
        isBiddablePrice(_auctionId, msg.value)
    {
        Auction storage auction = auctions[_auctionId];
        uint256 newAmount = auction.biddersToAmount[_msgSender()] + msg.value;
        auction.biddersToAmount[_msgSender()] = newAmount;
        auction.winner = _msgSender();
        auction.maxBidAmount = newAmount;

        emit BidUpdated(_auctionId, _msgSender(), newAmount);
    }

    function cancelBid(uint256 _auctionId)
        external
        nonReentrant
        isRunningAuction(_auctionId)
        isExistingBidder(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];

        uint256 msgSenderIndex = 0;
        if (_msgSender() == auction.winner) {
            // Current winner canceled bid, find next winner
            address newWinner = address(0);
            uint256 newMaxBidAmount = 0;
            for (uint256 i; i < auction.bidders.length; i++) {
                if (auction.bidders[i] != _msgSender()) {
                    if (
                        newMaxBidAmount <
                        auction.biddersToAmount[auction.bidders[i]]
                    ) {
                        newWinner = auction.bidders[i];
                        newMaxBidAmount = auction.biddersToAmount[newWinner];
                    }
                } else {
                    msgSenderIndex = i;
                }
            }

            auction.winner = newWinner;
            auction.maxBidAmount = newMaxBidAmount;
        } else {
            for (uint256 i; i < auction.bidders.length; i++) {
                if (auction.bidders[i] == _msgSender()) {
                    msgSenderIndex = i;
                    break;
                }
            }
        }

        uint256 bidAmount = auction.biddersToAmount[_msgSender()];

        auction.bidders[msgSenderIndex] = auction.bidders[
            auction.bidders.length - 1
        ];
        auction.bidders.pop();
        delete auction.biddersToAmount[_msgSender()];

        payable(_msgSender()).transfer(bidAmount);
    }

    function claim(uint256 _auctionId)
        external
        nonReentrant
        isExpiredAuction(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];

        if (
            auction.creator != _msgSender() &&
            auction.biddersToAmount[_msgSender()] == 0
        ) {
            revert NotBidder(_auctionId, _msgSender());
        } else if (auction.biddersToClaimed[_msgSender()]) {
            revert AlreadyWithdrawn(_auctionId, _msgSender());
        }

        auction.biddersToClaimed[_msgSender()] = true;

        if (auction.creator == _msgSender()) {
            if (auction.bidders.length == 0) {
                // No bidders, auction creator withdraw the nft
                _transfer721And1155(
                    address(this),
                    _msgSender(),
                    auction.nftAddress,
                    auction.tokenId,
                    auction.amount
                );
            } else {
                // Auction creater gets the winning bid amount
                uint256 amount = _payFee(
                    auction.nftAddress,
                    auction.tokenId,
                    auction.maxBidAmount
                );
                payable(_msgSender()).transfer(amount);
            }
        } else if (auction.winner == _msgSender()) {
            // Winner gets the NFT
            _transfer721And1155(
                address(this),
                _msgSender(),
                auction.nftAddress,
                auction.tokenId,
                auction.amount
            );
        } else {
            // Others withdraw their bid
            payable(_msgSender()).transfer(
                auction.biddersToAmount[_msgSender()]
            );
        }
    }

    function getAuctionDetailsById(uint256 _auctionId)
        external
        view
        isRunningAuction(_auctionId)
        returns (
            address nftAddress,
            uint256 tokenId,
            uint256 amount,
            address creator,
            uint256 startedAt,
            uint256 endAt,
            uint256 maxBidAmount,
            address winner,
            address[] memory bidders,
            uint256[] memory amounts
        )
    {
        Auction storage curAuction = auctions[_auctionId];

        amounts = new uint256[](curAuction.bidders.length);

        for (uint256 i; i < curAuction.bidders.length; i++) {
            amounts[i] = curAuction.biddersToAmount[curAuction.bidders[i]];
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