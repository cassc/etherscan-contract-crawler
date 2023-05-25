// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

// LICENSE
// BandSaurusAuctionHouse.sol is a modified version of nounsDAO's NounsAuctionHouse.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
//
// NounsAuctionHouse.sol source code Copyright nounsDAO licensed under the GPL-3.0 license.
// With modifications by Chimney Town DAO.

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IBandSaurusAuctionHouse } from './interfaces/IBandSaurusAuctionHouse.sol';
import { IBandSaurus } from './interfaces/IBandSaurus.sol';

contract BandSaurusAuctionHouse is IBandSaurusAuctionHouse, Ownable, ReentrancyGuard {

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "not paused");
        _;
    }

    // The BandSaurus ERC721 token contract
    IBandSaurus public bandSaurus;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer = 300; // 5min

    // Offset time for auction closing time (Based on UTC+0)
    uint256 public endTimeOffset = 3600 * 12;

    // The minimum price accepted in an auction
    uint256 public reservePrice = 10000000000000000; // 0.01eth

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage = 5; // 5%

    bool public paused = true;

    // The active auction
    IBandSaurusAuctionHouse.Auction public auction;

    /**
     * @notice Settle the current auction, mint a new BandSaurus, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction(0);
    }

    /**
     * @notice Settle the current auction.
     * @dev Only callable by the owner.
     */
    function settleAuction() external override onlyOwner nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Mint a new BandSaurus, and put it up for auction.
     * @dev Only callable by the owner.
     */
    function createAuction(uint256 startTime) external override onlyOwner nonReentrant whenPaused {
        IBandSaurusAuctionHouse.Auction memory _auction = auction;
        require(_auction.startTime == 0 || _auction.settled, 'Auction has not ended.');

        _createAuction(startTime);
    }

    /**
     * @notice Create a bid for a BandSaurus, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 tokenId) external payable override nonReentrant whenNotPaused {
        IBandSaurusAuctionHouse.Auction memory _auction = auction;

        require(tx.origin == msg.sender, "not eoa");
        require(_auction.tokenId == tokenId, 'BandSaurus not up for auction');
        require(block.timestamp > _auction.startTime, 'Auction not started');
        require(block.timestamp < _auction.endTime, 'Auction expired');
        require(msg.value >= reservePrice, 'Must send at least reservePrice');
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
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

    /**
     * @notice Pause the BandSaurus auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the BandSaurus auction house.
     * @dev This function can only be called by the owner.
     */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external override onlyOwner {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    function setEndTimeOffset(uint256 _endTimeOffset ) external override onlyOwner {
        endTimeOffset = _endTimeOffset;
    }

    function setBandSaurusContract(IBandSaurus _bandSaurus ) external onlyOwner {
        bandSaurus = _bandSaurus;
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction(uint256 startTime) internal {
        if(startTime > 0){
            require(block.timestamp < startTime, 'invalid value');
        }else{
            startTime = block.timestamp;
        }

        try bandSaurus.mint() returns (uint256 tokenId) {
            uint256 endTime = startTime  - startTime % 86400 + endTimeOffset;

            if(startTime >= endTime){
                endTime += 86400;
            }

            auction = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(tokenId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the BandSaurus is burned.
     */
    function _settleAuction() internal {
        IBandSaurusAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            bandSaurus.burn(_auction.tokenId);
        } else {
            bandSaurus.transferFrom(address(this), _auction.bidder, _auction.tokenId);
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(owner(), _auction.amount);
        }

        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails,send to Owner.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            require(_safeTransferETH(owner(), amount), "receiver rejected ETH transfer");
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    function _pause() internal {
        paused = true;
    }

    function _unpause() internal {
        paused = false;
    }

}