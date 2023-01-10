// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title: The Next 100 Years of Gucci
/// @author: niftykit.com

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BaseCollection.sol";

contract GucciVaultArtSpace is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC2981,
    ReentrancyGuard,
    AccessControl,
    Ownable,
    BaseCollection
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;

    // Minimum time buffer after a new bid is placed
    uint256 public immutable timeBuffer;

    // Minimum percentage bid amount
    uint96 public immutable minBidNumerator;

    // Base royalty percentage
    uint96 private immutable _baseFeeNumerator;

    mapping(uint256 => Auction) private _auctions;

    Counters.Counter private _auctionIdCounter;

    modifier hasAuction(uint256 auctionId) {
        require(
            _auctions[auctionId].creator != address(0),
            "Auction doesn't exist"
        );
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 timeBuffer_,
        uint96 minBidNumerator_,
        uint96 baseFeeNumerator_,
        address niftyKit_
    ) ERC721(name_, symbol_) BaseCollection(niftyKit_) {
        timeBuffer = timeBuffer_;
        minBidNumerator = minBidNumerator_;
        _baseFeeNumerator = baseFeeNumerator_;
        _auctionIdCounter.increment();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function createAuction(
        string calldata tokenURI_,
        address creator,
        uint256 reservePrice,
        uint256 duration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 auctionId = _auctionIdCounter.current();
        require(creator != address(0), "Creator must exist");
        require(duration >= timeBuffer, "Duration too short");

        _auctions[auctionId] = Auction({
            tokenURI: tokenURI_,
            creator: creator,
            reservePrice: reservePrice,
            duration: duration,
            amount: 0,
            bidder: address(0),
            active: false,
            startedAt: 0
        });

        _auctionIdCounter.increment();

        emit AuctionCreated(auctionId, creator);
    }

    function setAuction(
        uint256 auctionId,
        string calldata tokenURI_,
        address creator,
        uint256 reservePrice,
        uint256 duration
    ) external hasAuction(auctionId) onlyRole(DEFAULT_ADMIN_ROLE) {
        require(creator != address(0), "Creator must exist");
        require(duration >= timeBuffer, "Duration too short");

        _auctions[auctionId].tokenURI = tokenURI_;
        _auctions[auctionId].creator = creator;
        _auctions[auctionId].reservePrice = reservePrice;
        _auctions[auctionId].duration = duration;
    }

    function batchSetAuctionActive(uint256[] calldata auctionIds, bool active)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = auctionIds.length;
        for (uint256 i = 0; i < length; i++) {
            setAuctionActive(auctionIds[i], active);
        }
    }

    function setAuctionActive(uint256 auctionId, bool active)
        public
        hasAuction(auctionId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _auctions[auctionId].active = active;

        emit AuctionActive(auctionId, active);
    }

    function cancelAuction(uint256 auctionId)
        external
        hasAuction(auctionId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Auction memory auction = _auctions[auctionId];
        address bidder = auction.bidder;
        require(bidder != address(0), "Has no bidder");

        _auctions[auctionId].active = false;
        _auctions[auctionId].amount = 0;
        _auctions[auctionId].bidder = address(0);
        _auctions[auctionId].startedAt = 0;
        Address.sendValue(payable(bidder), auction.amount);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setTokenURI(
        uint256 tokenId,
        string calldata tokenURI_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenURI(tokenId, tokenURI_);
    }

    function getAuction(uint256 auctionId)
        external
        view
        hasAuction(auctionId)
        returns (
            string memory, // tokenURI
            address, // creator
            uint256, // reservePrice
            uint256, // duration
            uint256, // amount
            address, // bidder
            bool, // active
            uint256 // startedAt
        )
    {
        Auction memory auction = _auctions[auctionId];
        return (
            auction.tokenURI,
            auction.creator,
            auction.reservePrice,
            auction.duration,
            auction.amount,
            auction.bidder,
            auction.active,
            auction.startedAt
        );
    }

    function placeBid(uint256 auctionId)
        external
        payable
        hasAuction(auctionId)
        nonReentrant
    {
        Auction memory auction = _auctions[auctionId];

        require(auction.active, "Auction not active");
        require(msg.value > 0, "Has no value");
        require(msg.value >= auction.reservePrice, "Lower than reserve price");
        require(
            auction.startedAt == 0 ||
                block.timestamp < auction.startedAt.add(auction.duration),
            "Auction expired"
        );
        require(
            msg.value >=
                auction.amount.add(
                    auction.amount.mul(minBidNumerator).div(10000)
                ),
            "Lower than minimum bid amount"
        );

        // Start the auction when we receive the first bid
        if (auction.startedAt == 0) {
            _auctions[auctionId].startedAt = block.timestamp;
        }

        // Return the previous bid if there is any
        if (auction.bidder != address(0)) {
            Address.sendValue(payable(address(auction.bidder)), auction.amount);
        }

        // Extend duration if bid was placed below the time buffer
        if (
            _auctions[auctionId].startedAt.add(auction.duration).sub(
                block.timestamp
            ) < timeBuffer
        ) {
            uint256 prevDuration = auction.duration;
            _auctions[auctionId].duration = prevDuration.add(
                timeBuffer.sub(
                    auction.startedAt.add(prevDuration).sub(block.timestamp)
                )
            );
        }

        _auctions[auctionId].amount = msg.value;
        _auctions[auctionId].bidder = _msgSender();

        emit AuctionBidPlaced(auctionId, _msgSender(), msg.value);
    }

    function endAuction(uint256 auctionId)
        external
        hasAuction(auctionId)
        nonReentrant
    {
        Auction memory auction = _auctions[auctionId];

        require(auction.active, "Auction not active");
        require(auction.startedAt != 0, "Auction hasn't started");
        require(
            block.timestamp >= auction.startedAt.add(auction.duration),
            "Auction hasn't completed"
        );

        _safeMint(auction.bidder, auctionId);
        _setTokenURI(auctionId, auction.tokenURI);
        _setTokenRoyalty(auctionId, auction.creator, _baseFeeNumerator);

        _niftyKit.addFees(auction.amount);
        uint256 fees = _niftyKit.getFees(address(this));
        _niftyKit.addFeesClaimed(fees);

        Address.sendValue(payable(address(_niftyKit)), fees);
        Address.sendValue(payable(auction.creator), auction.amount.sub(fees));

        emit AuctionEnded(auctionId, auction.bidder, auction.amount);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}