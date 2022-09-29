// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISweepersAuctionHouse } from './interfaces/ISweepersAuctionHouse.sol';
import { ISweepersToken } from './interfaces/ISweepersToken.sol';
import { IWETH } from './interfaces/IWETH.sol';

contract SweepersAuctionHouse is ISweepersAuctionHouse, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // The Sweepers ERC721 token contract
    ISweepersToken public sweepers;

    // The address of the WETH contract
    address public weth;

    // The address of the Sweepers Dev
    address public sweepersDev;

    // The address of the Sweepers Treasury
    address public sweepersTreasury;

    // The address of the Metatopia Treasury
    address public metatopiaTreasury;

    uint16 public metatopiaPercent;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    ISweepersAuctionHouse.Auction public auction;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        ISweepersToken _sweepers,
        address _weth,
        address _sweepersDev,
        address _sweepersTreasury,
        address _metatopiaTreasury,
        uint16 _metatopiaPercent,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        sweepers = _sweepers;
        weth = _weth;
        sweepersDev = _sweepersDev;
        sweepersTreasury = _sweepersTreasury;
        metatopiaTreasury = _metatopiaTreasury;
        metatopiaPercent = _metatopiaPercent;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    /**
     * @notice Settle the current auction, mint a new Sweeper, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
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
     * @notice Create a bid for a Sweeper, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 sweeperId) external payable override nonReentrant {
        ISweepersAuctionHouse.Auction memory _auction = auction;

        require(_auction.sweeperId == sweeperId, 'Lil Sweeper not up for auction');
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

        emit AuctionBid(_auction.sweeperId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.sweeperId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the Sweepers auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Sweepers auction house.
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

    function setSweepersDev(address _sweepersDev) external override onlyOwner {
        sweepersDev = _sweepersDev;
    }

    function setSweepersTreasury(address _sweepersTreasury) external override onlyOwner {
        sweepersTreasury = _sweepersTreasury;
    }

    function setMetatopiaTreasury(address _metatopiaTreasury) external override onlyOwner {
        metatopiaTreasury = _metatopiaTreasury;
    }

    function setMetatopiaPercent(uint16 _metatopiaPercent) external override onlyOwner {
        metatopiaPercent = _metatopiaPercent;
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try sweepers.mint() returns (uint256 sweeperId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                sweeperId: sweeperId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(sweeperId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Sweeper is burned.
     */
    function _settleAuction() internal {
        ISweepersAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            sweepers.burn(_auction.sweeperId);
        } else {
            sweepers.transferFrom(address(this), _auction.bidder, _auction.sweeperId);
        }

        if (_auction.amount > 0) {
            if (_auction.sweeperId % 10 == 0) {
                _safeTransferETHWithFallback(sweepersDev, _auction.amount);
            } else if (metatopiaPercent > 0) {
                uint256 metatopiaAmount = _auction.amount * metatopiaPercent / 10000;
                uint256 sweepersAmount = _auction.amount - metatopiaAmount;
                _safeTransferETHWithFallback(sweepersTreasury, sweepersAmount);
                _safeTransferETHWithFallback(metatopiaTreasury, metatopiaAmount);
            } else {
                _safeTransferETHWithFallback(sweepersTreasury, _auction.amount);
            }
        }

        emit AuctionSettled(_auction.sweeperId, _auction.bidder, _auction.amount);
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
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
}