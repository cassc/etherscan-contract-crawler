// SPDX-License-Identifier: GPL-3.0

// The Wildxyz auctionhouse.sol

// AuctionHouse.sol is a modified version of the original code from the
// NounsAuctionHouse.sol which is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/
// licensed under the GPL-3.0 license.

// _pause() and _unpause() stop/starts all auctions/buyitnows
// state (0= auction + buy it now; 1= buy it now only)

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
    uint256 public state = 0; // 0 = auction + buy it now, 1 = buy it now only
    uint256 public timeBuffer = 120; // min amount of time left in an auction after last bid
    uint256 public minimumBid = .1 ether; // The minimum price accepted in an auction
    uint256 public duration = 300; // 86400 duration of the next auction in seconds; to end at next noon
    uint256 public constant fixedDuration = 300; // never changes
    uint8 public minBidIncrementPercentage = 10; // The minimum bid increment percentage
    address payable public payee; // The address that receives funds from the auction
    address[] public standingBidders; // list of addresses with standing bids
    address payable admin; // admin address (for buy now)

    Oasis public oasis; // The oasis contract

    uint256 public currentTokenId; // The current token ID being auctioned

    // The active auction
    IAuctionHouse.Auction public auction;

    // Only allow the auction functions to be active when not paused
    modifier onlyUnpaused() {
        require(!paused(), 'AuctionHouse: paused');
        _;
    }

    // modifier for onlyOwner or admin
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == admin, 'AuctionHouse: only owner or admin');
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

    // mapping of buy it now prices: tokenId => price
    mapping(uint256 => uint256) public buyNowPrices;

    constructor(Oasis _oasis) {
        oasis = _oasis;
        // set the payee to the contract owner
        payee = payable(0x710900ca8c7C280B0E6bb005e60dFE1cf6E5FA4c);
        admin = payable(msg.sender);
        _pause();
    }

    /* ADMIN VARIABLE SETTERS FUNCTIONS */

    // add/edit buy it now price mapping
    function setBuyNowPrices(uint256[] calldata _tokenId, uint256[] calldata _price) external onlyOwnerOrAdmin {
        require(_tokenId.length == _price.length, 'AuctionHouse: invalid input');
        for (uint256 i = 0; i < _tokenId.length; i++) {
            buyNowPrices[_tokenId[i]] = _price[i];
        }
    }

    // change the state
    function setState(uint256 _state) external onlyOwnerOrAdmin {
        require(state < 2, 'AuctionHouse: invalid state');
        state = _state;
    }


    // edit admin address
    function setAdmin(address payable _admin) external onlyOwner {
        admin = _admin;
    } 

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
    function setMinimumBid(uint256 _minimumBid) external onlyOwnerOrAdmin {
        minimumBid = _minimumBid;
    }

    // change close time of current auction
    function changeCloseTime(uint256 _closeTime) external onlyOwnerOrAdmin {
        auction.endTime = _closeTime;
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
    function withdraw() external onlyOwner {
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

    // cancel all standing bids admin only
    function cancelAllStandingBid() public nonReentrant onlyOwner {
        IAuctionHouse.Auction memory _auction = auction; 
        // loop through standing bidders
        for (uint i = 0; i < standingBidders.length; i++) {
            if (_auction.bidder != standingBidders[i]) {
                // not highest bidder, refund
                _safeTransferETH(standingBidders[i], Bids[standingBidders[i]].amount);
                Bids[standingBidders[i]].refunded = true;
            }
            Bids[standingBidders[i]].standing = false;
            // update list of standing bidders
            standingBidders[i] = standingBidders[standingBidders.length - 1];
            standingBidders.pop();
            emit CancelStandingBid(standingBidders[i]);
        }

    }

    // admin can place bid on behalf of bidder
    function ownerBidOnBehalf(uint256 _currentTokenId, bool _standing, address _bidder) external payable nonReentrant onlyOwner {

        // Query the auction state
        IAuctionHouse.Auction memory _auction = auction; 

        // Check that the auction is live
        require(_currentTokenId == _auction.tokenId, 'Bid on wrong tokenId.');
        require(block.timestamp < _auction.endTime, "Auction has ended");
        require(block.timestamp > _auction.startTime, "Auction has not started");
        require(msg.value >= minimumBid, "Bid is too low.");
        require(msg.value > _auction.amount, "Bid is too low.");

        // A reference to benchmark the new bid against
        address payable lastBidder = _auction.bidder;

        // Refund the previous highest bidder,
        // if not standing bid
        if (lastBidder != address(0) && Bids[lastBidder].standing == false && Bids[lastBidder].refunded == false) {
            _safeTransferETH(lastBidder, _auction.amount);
            Bids[lastBidder].refunded = true;
        }

        // if overbidding self, remove old bid
        // clear standing bids from same sender
        if (Bids[_bidder].refunded == false) {
            if (Bids[_bidder].standing == true) {
                // loop through standing bidders and remove the address
                for (uint i = 0; i < standingBidders.length; i++) {
                    if (standingBidders[i] == _bidder) {
                        standingBidders[i] = standingBidders[standingBidders.length - 1];
                        standingBidders.pop();
                        break;
                    }
                }
            }
            _safeTransferETH(_bidder, Bids[_bidder].amount);
            Bids[_bidder].refunded = true;
        }

        Bid memory new_bid;
        new_bid.bidder = payable(_bidder);
        new_bid.amount = msg.value;
        new_bid.timestamp = block.timestamp;
        new_bid.winner = false;
        new_bid.refunded = false;
        new_bid.standing = _standing;
        Bids[_bidder] = new_bid;

        if (_standing == true) {
            standingBidders.push(_bidder);
        }

        // Update the auction state with the new bid bidder and the new amount
        auction.bidder = payable(_bidder);
        auction.amount = msg.value;


        // Extend the auction if the bid was received within the time buffer
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = _auction.endTime + timeBuffer;
            auction.extendedTime = _auction.extendedTime + timeBuffer;
        }

        emit AuctionBid(currentTokenId, _bidder, Bids[_bidder].amount, _standing, extended, false); 

        if (extended) {
            emit AuctionExtended(currentTokenId, _auction.endTime);
        }

    }


    // Bidder cancel standing bid
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

        IAuctionHouse.Auction memory _auction = auction; 
        address payable lastBidder = _auction.bidder;
        uint256 _bidAmount;

        // Check that the auction is live
        require(_currentTokenId == _auction.tokenId, 'Bid on wrong tokenId.');
        require(block.timestamp < _auction.endTime, "Auction has ended");
        require(block.timestamp > _auction.startTime, "Auction has not started");
 
 
        // if not standing bid, and not current bidder: refund high bidder
        if (lastBidder != address(0) && Bids[lastBidder].standing == false && Bids[lastBidder].refunded == false && lastBidder != msg.sender) {
            _safeTransferETH(lastBidder, _auction.amount);
            Bids[lastBidder].refunded = true;
        }

        // upsert this bid
        if (lastBidder == msg.sender || (Bids[msg.sender].standing == true && Bids[msg.sender].refunded == false)) {
            // if current high bidder or losing standing bid:  update the Bid struct
            _bidAmount = Bids[msg.sender].amount + msg.value;
            require(
                (
                    _bidAmount >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100)
                )
                ||
                (
                    buyNowPrices[_currentTokenId] > 0 && _bidAmount >= buyNowPrices[_currentTokenId] 
                ), 
                "Bid is too low."
            );
            Bids[msg.sender].amount = _bidAmount;
            Bids[msg.sender].timestamp = block.timestamp;
            Bids[msg.sender].refunded = false;

            // if bidder is changing standing status, update standingBidders array
            if (_standing == true && Bids[msg.sender].standing == false) {
                standingBidders.push(msg.sender);
            } else if (_standing == false && Bids[msg.sender].standing == true) {
                // loop through standing bidders and remove the address
                for (uint i = 0; i < standingBidders.length; i++) {
                    if (standingBidders[i] == msg.sender) {
                        standingBidders[i] = standingBidders[standingBidders.length - 1];
                        standingBidders.pop();
                        break;
                    }
                }
            }
            Bids[msg.sender].standing = _standing;

        } else {
            require(
                (
                    msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100)
                )
                ||
                (
                    buyNowPrices[_currentTokenId] > 0 && msg.value >= buyNowPrices[_currentTokenId]
                ), 
                "Bid is too low."
            );
            require(msg.value >= minimumBid, "Bid is too low."); 
            // else, add new bid to Bid struct
            _bidAmount = msg.value;
            Bid memory new_bid;
            new_bid.bidder = payable(msg.sender);
            new_bid.amount = _bidAmount;
            new_bid.timestamp = block.timestamp;
            new_bid.winner = false;
            new_bid.refunded = false;
            new_bid.standing = _standing;
            Bids[msg.sender] = new_bid;

            if (_standing == true) {
                standingBidders.push(msg.sender);
            }
        }

        // Update the auction state with the new bid bidder and the new amount
        auction.bidder = payable(msg.sender);
        auction.amount = _bidAmount;

        // Extend the auction if the bid was received within the time buffer
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = _auction.endTime + timeBuffer;
            auction.extendedTime = _auction.extendedTime + timeBuffer;
        }

        emit AuctionBid(currentTokenId, msg.sender, _bidAmount, _standing, extended, false); 

        if (extended) {
            emit AuctionExtended(currentTokenId, _auction.endTime);
        }

        // if this bid >= buy it now price:
        //   set duration to clsoetime -now + duration
        //   set close time to now
        if (buyNowPrices[_currentTokenId] > 0 && _bidAmount >= buyNowPrices[_currentTokenId]) {
            duration = _auction.endTime - block.timestamp + duration;
            auction.endTime = _auction.endTime = block.timestamp;
            emit BuyNow(_currentTokenId, msg.sender, _bidAmount);
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
            uint256 _newEndTime;

            if (state == 1 && buyNowPrices[tokenId] >= 0) {
                _newEndTime = block.timestamp + 3153600000; // 100 years in seconds is 3153600000
                minimumBid = buyNowPrices[tokenId];
            } else {
                _newEndTime = block.timestamp + duration - _auction.extendedTime;
                minimumBid = .1 ether; 
            }

            auction = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: block.timestamp,
                endTime: _newEndTime, 
                bidder: payable(0),
                settled: false,
                extendedTime: 0
            });

            currentTokenId = tokenId;
            duration = fixedDuration;

            if (state == 1 && buyNowPrices[tokenId] == 0) {
                _pause();
            }

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