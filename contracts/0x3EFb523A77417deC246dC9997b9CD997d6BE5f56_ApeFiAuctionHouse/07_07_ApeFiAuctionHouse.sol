// SPDX-License-Identifier: GPL-3.0

// LICENSE
// ApeFiAuctionHouse.sol is a modified version of Nouns DAO's NounsAuctionHouse.sol:
// https://etherscan.io/address/0xf15a943787014461d94da08ad4040f79cd7c124e#code
//
// NounsAuctionHouse.sol source code Copyright Nouns DAO licensed under the GPL-3.0 license.
// With modifications by ApeFi.

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ApeFiAuctionHouse is Ownable, ReentrancyGuard, Pausable {
    IERC721 public immutable apeFiNFT;

    address public immutable deployer;

    uint256 public constant LAST_SALE_TOKEN_ID = 9998;

    uint256 public minPrice;

    uint256[] public DURATIONS = [1 days, 12 hours, 6 hours, 3 hours, 1 hours];

    uint8 public durationIndex;

    uint256 public timeBuffer;

    uint8 public minBidIncrementPercentage;

    struct Auction {
        uint256 tokenId;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        address bidder;
        bool settled;
    }

    Auction public auction;

    uint256 public lastBidTokenId;

    uint256 public lastBidAmount;

    event AuctionCreated(uint256 indexed tokenId, uint256 startTime, uint256 endTime);

    event AuctionSettled(uint256 indexed tokenId, address bidder, uint256 amount);

    event AuctionBid(uint256 indexed tokenId, address bidder, uint256 amount, bool extended);

    event AuctionExtended(uint256 indexed tokenId, uint256 endTime);

    event AuctionMinPriceUpdated(uint256 minPrice);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionMinBidIncrementPercentageUpdated(uint8 minBidIncrementPercentage);

    event LastBidTokenIdUpdated(uint256 lastBidTokenId);

    constructor(
        address apeFiNFT_,
        address deployer_,
        uint256 minPrice_,
        uint256 timeBuffer_,
        uint8 minBidIncrementPercentage_
    ) {
        apeFiNFT = IERC721(apeFiNFT_);
        deployer = deployer_;
        minPrice = minPrice_;
        timeBuffer = timeBuffer_;
        minBidIncrementPercentage = minBidIncrementPercentage_;

        _pause();
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "contract cannot operate");
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function settleCurrentAndCreateNewAuction() external whenNotPaused nonReentrant onlyEOA {
        _settleAuction();
        _createAuction();
    }

    function settleAuction() external whenPaused nonReentrant onlyEOA {
        _settleAuction();
    }

    function createBid() external payable whenNotPaused nonReentrant onlyEOA {
        Auction memory _auction = auction;

        require(block.timestamp < _auction.endTime, "auction ended");
        require(msg.value >= minPrice, "less than min price");
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            "not satisfy bid increment rule"
        );

        // Refund the last bidder, if applicable
        if (_auction.bidder != address(0)) {
            (bool sent,) = payable(_auction.bidder).call{value: _auction.amount}("");
            require(sent, "failed to send ether");
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.tokenId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.tokenId, _auction.endTime);
        }
    }

    function buyoutAndSettle() external payable whenNotPaused nonReentrant onlyEOA {
        Auction memory _auction = auction;

        require(block.timestamp >= _auction.endTime, "auction not ended");
        require(msg.value >= minPrice, "less than min price");
        require(_auction.bidder == address(0), "bidder exist");

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        _settleAuction();
        _createAuction();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    function setMinPrice(uint256 _minPrice) external onlyOwner {
        minPrice = _minPrice;

        emit AuctionMinPriceUpdated(_minPrice);
    }

    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    function setLastBidTokenId(uint256 _lastBidTokenId) external onlyOwner {
        lastBidTokenId = _lastBidTokenId;

        emit LastBidTokenIdUpdated(_lastBidTokenId);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _createAuction() internal {
        if (lastBidTokenId == LAST_SALE_TOKEN_ID) {
            _pause();
            return;
        }

        uint256 tokenId = lastBidTokenId + 1;
        while (apeFiNFT.ownerOf(tokenId) != deployer) {
            tokenId += 1;
        }

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + DURATIONS[durationIndex];

        auction = Auction({
            tokenId: tokenId,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false
        });

        emit AuctionCreated(tokenId, startTime, endTime);
    }

    function _settleAuction() internal {
        Auction memory _auction = auction;

        require(_auction.startTime != 0, "not started");
        require(!_auction.settled, "already settled");
        require(block.timestamp >= _auction.endTime, "auction not ended");
        require(_auction.bidder != address(0), "empty bidder");

        auction.settled = true;

        // Adjust the duration index for the next auction.
        if (lastBidAmount > 0 && _auction.amount >= lastBidAmount && durationIndex < DURATIONS.length - 1) {
            durationIndex += 1;
        } else if (_auction.amount < lastBidAmount && durationIndex > 0) {
            durationIndex -= 1;
        }

        // Update the previous bid amount and token ID.
        lastBidAmount = _auction.amount;
        lastBidTokenId = _auction.tokenId;

        apeFiNFT.transferFrom(deployer, _auction.bidder, _auction.tokenId);

        (bool sent,) = payable(owner()).call{value: _auction.amount}("");
        require(sent, "failed to send ether");

        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);
    }
}