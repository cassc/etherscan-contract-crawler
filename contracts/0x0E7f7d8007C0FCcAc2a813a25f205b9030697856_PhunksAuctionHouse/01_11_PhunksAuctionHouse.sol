// SPDX-License-Identifier: GPL-3.0
/********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░██████████████████████░░░ *
 * ░░░██░░░░░░██░░░░░░████░░░░░ *
 * ░░░██░░░░░░██░░░░░░██░░░░░░░ *
 * ░░░██████████████████░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 ************************♥tt****/

// LICENSE
// PhunksAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol

// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by Nounders DAO and ogkenobi.eth
// Not affiliated with Not Larva Labs

pragma solidity ^0.8.15;

import { Pausable } from '@openzeppelin/contracts/security/Pausable.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IPhunksAuctionHouse } from './interfaces/IPhunksAuctionHouse.sol';
import { IPhunksToken } from './interfaces/IPhunksToken.sol';
import { IWETH } from './interfaces/IWETH.sol';

contract PhunksAuctionHouse is IPhunksAuctionHouse, Pausable, ReentrancyGuard, Ownable {
    // The Phunks ERC721 token contract
    IPhunksToken public phunks;

    // The address of the WETH contract
    address public weth;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The curren auction ID number
    uint256 public auctionId = 0;

    // The active auction
    IPhunksAuctionHouse.Auction public auction;

    // The Treasury wallet
    address public treasuryWallet;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        IPhunksToken _phunks,
        address _weth,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration,
        address _treasuryWallet
    ) public onlyOwner {

        _pause();

        phunks = _phunks;
        weth = _weth;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
        treasuryWallet = _treasuryWallet;
    }

    /**
     * @notice Settle the current auction, mint a new Phunk, and put it up for auction.
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
     * @notice Create a bid for a Phunk, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint phunkId) external payable override nonReentrant {
        IPhunksAuctionHouse.Auction memory _auction = auction;

        require(_auction.phunkId == phunkId, 'Phunk not up for auction');
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

        emit AuctionBid(_auction.phunkId, auctionId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.phunkId, auctionId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the Phunks auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Phunks auction house.
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
     * @notice Set the treausury wallet address.
     * @dev Only callable by the owner.
     */
     function setTreasuryWallet(address _treasuryWallet) public onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    /**
     * @notice Set the duration of an auction
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 _duration) external override onlyOwner {
        duration = _duration;

        emit AuctionDurationUpdated(_duration);
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

    /**
     * @notice Generates a big random number on the cheap.
     * 
     */
    function _getRand() internal view returns(uint256) {
        uint256 randNum = uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty +  
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number)));
        
        return randNum;
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */

    function _createAuction() internal {
        uint treasuryBalance = phunks.balanceOf(treasuryWallet);
        require(treasuryBalance > 0, "No Phunks available for auction.");

        uint randomIndex = _getRand() % treasuryBalance;
        uint phunkId = phunks.tokenOfOwnerByIndex(treasuryWallet, randomIndex);
        //removes 7-trait phunk from random selection
        if (phunkId == 8348) {
            require(treasuryBalance > 1, "No Phunks available for auction.");

            uint nextIndex = (randomIndex + 1) % treasuryBalance;
            phunkId = phunks.tokenOfOwnerByIndex(treasuryWallet, nextIndex);
            
        }

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        auctionId++;

        auction = Auction({
            phunkId: phunkId,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false,
            auctionId: auctionId
        });

        emit AuctionCreated(phunkId, auctionId, startTime, endTime);
    }
    /**
     * @notice Create an speacial auction for specific phunkID
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function createSpecialAuction(uint _phunkId, uint256 _endTime) public onlyOwner {
        require(phunks.balanceOf(treasuryWallet) > 0, "No Phunks available for auction.");
        require(phunks.ownerOf(_phunkId) == treasuryWallet, "Phunk does not exist in treasury wallet");
        uint phunkId = _phunkId;
        uint256 startTime = block.timestamp;
        uint256 endTime = _endTime;
        auctionId++;

        auction = Auction({
            phunkId: phunkId,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false,
            auctionId: auctionId
        });

        emit AuctionCreated(phunkId, auctionId, startTime, endTime);
    
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Phunk is burned.
     */
    function _settleAuction() internal {
        IPhunksAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidder != address(0)) {
            phunks.transferFrom(address(treasuryWallet), _auction.bidder, _auction.phunkId);
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(treasuryWallet, _auction.amount);
        }

        emit AuctionSettled(_auction.phunkId, auctionId, _auction.bidder, _auction.amount);
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