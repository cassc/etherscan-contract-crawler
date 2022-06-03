// SPDX-License-Identifier: GPL-3.0

/// @title The NiftyPride Auction House

/************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░████░░████░░██░░████░░░░████░░ *
 * ░░█░░█░░█░░█░░██░░█░░░█░░░█░░░░░ *
 * ░░████░░███░░░██░░█░░░░█░░███░░░ *
 * ░░█░░░░░█░█░░░██░░█░░░█░░░█░░░░░ *
 * ░░█░░░░░█░░█░░██░░████░░░░████░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 ***********************************/

// LICENSE
// NiftyPrideAuctionHouse.sol is a modified version of Noun's NounsAuctionHouse.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/17e61ecaf6f1c66ca8035bf4e0c3c8dae58ca937/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
//
// and is published under the same GPL-3.0 license

pragma solidity ^0.8.6;

import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import {IAuctionHouse} from './interfaces/IAuctionHouse.sol';
import {IWETH} from './interfaces/IWETH.sol';

contract NiftyPrideAuctionHouse is
    IAuctionHouse,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    error WrongAuction();
    error AuctionExpired();
    error ReservePriceNotMet();
    error BidTooLow();

    error AuctionNotStarted();
    error AuctionAlreadySettled();
    error AuctionNotEnded();

    error RegistryNotSet();

    /// @notice The address of the WETH contract
    address public weth;

    /// @notice The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer = 10 minutes;

    /// @notice The minimum price accepted in an auction
    uint256 public reservePrice = 0.01 ether;

    /// @notice The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage = 5;

    /// @notice The duration of a single auction
    uint256 public duration = 24 hours;

    /// @notice The active auction
    IAuctionHouse.Auction public auction;

    constructor(address weth_) {
        _pause();

        if (block.chainid == 1) {
            weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (block.chainid == 4) {
            weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        } else {
            weth = weth_;
        }
    }

    ////////////////////////////////////////////////////
    ///// Public                                      //
    ////////////////////////////////////////////////////

    /**
     * @notice Settle the current auction, mint a new token, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction()
        external
        override
        nonReentrant
        whenNotPaused
    {
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a token, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 tokenId) external payable override nonReentrant {
        IAuctionHouse.Auction memory _auction = auction;

        if (_auction.tokenId != tokenId) revert WrongAuction();
        if (block.timestamp >= _auction.endTime) revert AuctionExpired();
        if (msg.value < reservePrice) revert ReservePriceNotMet();

        if (
            msg.value <
            _auction.amount +
                ((_auction.amount * minBidIncrementPercentage) / 100)
        ) {
            revert BidTooLow();
        }

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

    ////////////////////////////////////////////////////
    ///// Contract owner                              //
    ////////////////////////////////////////////////////

    /**
     * @notice Pause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
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
    function setReservePrice(uint256 _reservePrice)
        external
        override
        onlyOwner
    {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        override
        onlyOwner
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(
            _minBidIncrementPercentage
        );
    }

    ////////////////////////////////////////////////////
    ///// Internals                             //
    ////////////////////////////////////////////////////

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal virtual {
        uint256 tokenId = _mintNext();

        if (tokenId > 0) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(tokenId, startTime, endTime);
        } else {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the token is sent to the current contract owner (and after to its creator).
     */
    function _settleAuction() internal {
        IAuctionHouse.Auction memory _auction = auction;

        if (_auction.startTime == 0) revert AuctionNotStarted();
        if (_auction.settled) revert AuctionAlreadySettled();
        if (block.timestamp < _auction.endTime) revert AuctionNotEnded();

        auction.settled = true;

        ERC721(_getRegistry()).transferFrom(
            address(this),
            (
                _auction.bidder == address(0)
                    ? owner() // if no bidder, send to owner() so it can go back to creator
                    : _auction.bidder
            ),
            _auction.tokenId
        );

        if (_auction.amount > 0) {
            _transferToRecipients(_auction.tokenId, _auction.amount);
        }

        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    /// @dev internal function to allow transfer to revenue recipient(s), default to owner()
    function _transferToRecipients(uint256, uint256 amount) internal virtual {
        _safeTransferETHWithFallback(owner(), amount);
    }

    /// @dev internal function to mint next token, must be overrode
    function _mintNext() internal virtual returns (uint256) {
        return 0;
    }

    /// @dev internal function to get nft contract holder, must be overrode
    function _getRegistry() internal virtual returns (address) {
        return address(0);
    }
}