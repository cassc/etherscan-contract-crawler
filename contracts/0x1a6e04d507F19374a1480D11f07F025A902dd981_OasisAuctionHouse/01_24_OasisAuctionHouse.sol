// SPDX-License-Identifier: GPL-3.0

// The Wildxyz auctionhouse.sol

// AuctionHouse.sol is a modified version of the original code from the
// NounsAuctionHouse.sol which is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/
// licensed under the GPL-3.0 license.

pragma solidity ^0.8.18;

import './Pausable.sol';
import './ReentrancyGuard.sol';
import './Ownable.sol';
import './IOasis.sol';
import './IAuctionHouse.sol';

contract OasisAuctionHouse is
    IAuctionHouse,
    Pausable,
    ReentrancyGuard,
    Ownable
{

    // auction variables
    uint256 public timeBuffer = 120; // min amount of time left in an auction after last bid
    uint256 public minimumBid = .1 ether; // The minimum price accepted in an auction
    uint256 public duration = 86400; // 86400 == 1 day /The duration of a single auction in seconds
    uint8 public minBidIncrementPercentage = 10; // The minimum bid increment percentage
    address payable public payee; // The address that receives funds from the auction
    address[] public standingBidders; // list of addresses with standing bids

    Oasis public oasis; // The oasis contract

    uint256 public currentTokenId; // The current token ID being auctioned

    // The active auction
    IAuctionHouse.Auction public auction;

    // Only allow the auction functions to be active when not paused
    modifier onlyUnpaused() {
        require(!paused(), 'AuctionHouse: paused');
        _;
    }

    // Bids Struct
    struct Bid {
        address payable bidder; // The address of the bidder
        uint256 amount; // The amount of the bid
        bool minted; // has the bid been minted
        uint256 timestamp; // timestamp of the bid
        bool refunded; // refund difference between winning_bid and max_bid for winner; and all for losers // enter reentrancy guard
        bool winner; // is the bid the winner
        bool standing; // if not winner, bid rolls to next auction
    }

    // mapping of Bid structs
    mapping(address => Bid) public Bids;

    constructor(Oasis _oasis) {
        oasis = _oasis;
        // set the payee to the contract owner
        payee = payable(0x710900ca8c7C280B0E6bb005e60dFE1cf6E5FA4c);
        _pause();
    }

    /* ADMIN VARIABLE SETTERS FUNCTIONS */

    // set the 721 contract address
    function set721ContractAddress(Oasis _newOasis) public onlyOwner {
        oasis = _newOasis;
    }

    // set the time buffer
    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner override {
        timeBuffer = _timeBuffer;
        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    // set the minimum bid
    function setMinimumBid(uint256 _minimumBid) external onlyOwner {
        minimumBid = _minimumBid;
    }

    // set the duration
    function setDuration(uint256 _duration) external onlyOwner override {
        duration = _duration;
        emit AuctionDurationUpdated(_duration);
    }

    // set the min bid increment percentage
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        onlyOwner
        override
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;
        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    // promo mint
    function promoMint(address _to, uint256 _qty) external onlyOwner {
        oasis.promoMint(_to, _qty);
    }

    // pause
    function pause() external onlyOwner override {
        _pause();
    }

    // unpause
    function unpause() external onlyOwner override {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    // Settle the current auction (only when paused)
    function settleAuction() external whenPaused onlyOwner nonReentrant override {
        _settleAuction();
    }

    // withdraw
    function withdraw() public {
        (bool success, ) = payee.call{value: address(this).balance}("");
        require(success, "Failed to send to payee.");
    }

    // update payee for withdraw
    function setPayee(address payable _payee) public onlyOwner {
        payee = _payee;
    }

    /* END ADMIN VARIABLE SETTERS FUNCTIONS */

    /* PUBLIC FUNCTIONS */

    // Settles and creates a new auction
    function settleCurrentAndCreateNewAuction() external nonReentrant override {
        _settleAuction();
        _createAuction();
        _processStandingBids();
        require(block.timestamp >= auction.startTime, 'AuctionHouse: auction not started');
    }

    // adds highest standing bid to newly created auction
    function _processStandingBids() internal {
        IAuctionHouse.Auction memory _auction = auction; 
        uint256 this_amount = 0;
        address this_bidder;
        // loop through standing bidders and add the highest bid to the new auction
        // also emit all the bids so they will attach to new auction
        for (uint i = 0; i < standingBidders.length; i++) {
            if (Bids[standingBidders[i]].amount > this_amount 
                    && Bids[standingBidders[i]].refunded == false
                    && Bids[standingBidders[i]].standing == true) {
                this_amount = Bids[standingBidders[i]].amount;
                this_bidder = standingBidders[i];
            }
            emit AuctionBid(
                _auction.tokenId, 
                standingBidders[i],
                Bids[standingBidders[i]].amount, 
                true, 
                false,
                true
            );
        }
        if (this_amount > 0) {
            auction.bidder = payable(this_bidder);
            auction.amount = this_amount;
        }


    }

    // Cancel standing bid
    function cancelStandingBid() public nonReentrant {
        IAuctionHouse.Auction memory _auction = auction; 
        require(Bids[msg.sender].standing == true, "No standing bid to cancel.");

        if (_auction.bidder != msg.sender) {
            // not highest bidder, refund
            _safeTransferETH(msg.sender, Bids[msg.sender].amount);
            Bids[msg.sender].refunded = true;
        }
        Bids[msg.sender].standing = false;
        // loop through standing bidders and remove the address
        for (uint i = 0; i < standingBidders.length; i++) {
            if (standingBidders[i] == msg.sender) {
                standingBidders[i] = standingBidders[standingBidders.length - 1];
                standingBidders.pop();
                break;
            }
        }

        emit CancelStandingBid(msg.sender);
        
    }


    // Creates bids for the current auction
    function createBid(uint256 _currentTokenId, bool _standing) external payable nonReentrant  onlyUnpaused {

        // Query the auction state
        IAuctionHouse.Auction memory _auction = auction; 

        // Check that the auction is live
        require(_currentTokenId == _auction.tokenId, 'Bid on wrong tokenId.');
        require(block.timestamp < _auction.endTime, "Auction has ended");
        require(block.timestamp > _auction.startTime, "Auction has not started");
        require(msg.value >= minimumBid, "Bid is too low.");
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100), 
            "Bid is too low."
        );

        // A reference to benchmark the new bid against
        address payable lastBidder = _auction.bidder;

        // Refund the previous highest bidder,
        // if not standing bid
        if (lastBidder != address(0) && Bids[lastBidder].standing == false && Bids[msg.sender].refunded == false) {
            _safeTransferETH(lastBidder, _auction.amount);
            Bids[lastBidder].refunded = true;
        }

        // if overbidding self, remove old bid
        // clear standing bids from same sender
        if (Bids[msg.sender].refunded == false) {
            if (Bids[msg.sender].standing == true) {
                // loop through standing bidders and remove the address
                for (uint i = 0; i < standingBidders.length; i++) {
                    if (standingBidders[i] == msg.sender) {
                        standingBidders[i] = standingBidders[standingBidders.length - 1];
                        standingBidders.pop();
                        break;
                    }
                }
            }
            _safeTransferETH(msg.sender, Bids[msg.sender].amount);
            Bids[msg.sender].refunded = true;
        }

        Bid memory new_bid;
        new_bid.bidder = payable(msg.sender);
        new_bid.amount = msg.value;
        new_bid.timestamp = block.timestamp;
        new_bid.winner = false;
        new_bid.refunded = false;
        new_bid.standing = _standing;
        Bids[msg.sender] = new_bid;

        if (_standing == true) {
            standingBidders.push(msg.sender);
        }

        // Update the auction state with the new bid bidder and the new amount
        auction.bidder = payable(msg.sender);
        auction.amount = msg.value;


        // Extend the auction if the bid was received within the time buffer
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = _auction.endTime + timeBuffer;
            auction.extendedTime = _auction.extendedTime + timeBuffer;
        }

        emit AuctionBid(currentTokenId, msg.sender, Bids[msg.sender].amount, _standing, extended, false); 

        if (extended) {
            emit AuctionExtended(currentTokenId, _auction.endTime);
        }

    }
    

    /* END PUBLIC FUNCTIONS */

    /* INTERNAL FUNCTIONS */

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try oasis.mint(address(this)) returns (uint256 tokenId) {
            require(auction.endTime < block.timestamp, "AuctionHouse: auction not ended");

            IAuctionHouse.Auction memory _auction = auction;

            auction = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: block.timestamp,
                endTime: block.timestamp + duration - _auction.extendedTime,
                bidder: payable(0),
                settled: false,
                extendedTime: 0
            });

            currentTokenId = tokenId;

            emit AuctionCreated(tokenId, auction.startTime, auction.endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * Settle an auction, finalizing the bid and paying out to the owner.
     * If there are no bids, the Oasis is burned.
     */
    function _settleAuction() internal {
        require(auction.startTime != 0, "Auction hasn't begun");
        IAuctionHouse.Auction memory _auction = auction;

        Bid storage winning_bid = Bids[_auction.bidder];

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            oasis.burn(_auction.tokenId);
        } else {
            oasis.transferFrom(
                address(this),
                _auction.bidder,
                _auction.tokenId
            );
             winning_bid.winner = true;
             winning_bid.minted = true;
             if (winning_bid.standing == true) {
                 winning_bid.standing = false;
                // loop through standing bidders and remove the address
                for (uint i = 0; i < standingBidders.length; i++) {
                    if (standingBidders[i] == _auction.bidder) {
                        standingBidders[i] = standingBidders[standingBidders.length - 1];
                        standingBidders.pop();
                        break;
                    }
                }
             }
        }

        if (_auction.amount > 0) {
            _safeTransferETH(payee, _auction.amount);
        }

        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);
    }

    /**
     * Transfer ETH and return the success status.
     * This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }
}